defmodule KubeServices.KubeState.ResourceWatcher do
  @moduledoc """
  This module is a genserver that pushes all the data about different resources types into kube state table.


  It does this by:
  - listing all existing resources
  - Adding those to the table
  - Then starting a watch on the resource type
  - handling every event after that

  One single lazy connection to kube is used.
  Errors in the list or watch cause everything to be retried after some time
  """
  use GenServer
  use TypedStruct

  alias CommonCore.ApiVersionKind
  alias CommonCore.ConnectionPool
  alias CommonCore.K8s.Client
  alias KubeServices.KubeState.Runner

  require Logger

  typedstruct module: State do
    field :resource_type, atom(), enforce: true
    field :table_name, atom(), enforce: true

    field :retry_ms, non_neg_integer(), default: 100
    field :max_retry_ms, non_neg_integer(), default: 120_000
    field :jitter_min, float(), default: 0.75
    field :jitter_max, float(), default: 1.25

    field :conn, K8s.Conn.t() | nil

    # For mocking
    field :client, module(), default: Client
    field :runner, module(), default: Runner

    def new!(opts) do
      conn_func = Keyword.get(opts, :conn_func, &ConnectionPool.get!/0)

      # Get the connection now if one wasn't provided
      conn = Keyword.get_lazy(opts, :conn, fn -> conn_func.() end)

      struct!(__MODULE__, Keyword.put(opts, :conn, conn))
    end
  end

  @state_opts ~w(resource_type table_name conn conn_func retry_ms jitter_min jitter_max client runner )a

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    {state_opts, gen_opts} = Keyword.split(opts, @state_opts)

    {:ok, pid} = result = GenServer.start_link(__MODULE__, state_opts, gen_opts)
    Logger.debug("GenServer started with #{inspect(pid)}. #{inspect(gen_opts)}")
    result
  end

  @impl GenServer
  def init(opts) do
    state = State.new!(opts)

    {:ok, state, {:continue, :start_watch}}
  end

  @impl GenServer
  def handle_continue(:start_watch, state) do
    start_watch(state)
  end

  @impl GenServer
  def handle_info(:start_watch, state) do
    start_watch(state)
  end

  defp start_watch(state) do
    with {:ok, fetch_state} <- fetch_initial(state),
         {:ok, watch_state} <- watch(fetch_state) do
      {:noreply, watch_state}
    else
      {:error, _reason} ->
        # wait and try again
        {delay, new_state} = next_delay(state)
        Process.send_after(self(), :start_watch, delay)
        {:noreply, new_state}
    end
  end

  defp next_delay(%State{retry_ms: current_time, max_retry_ms: max_time} = state) do
    # Rather than do doubling we do a random percent increase between jitter_min and jitter_max
    percent_to_add = :rand.uniform() * (state.jitter_max - state.jitter_min) + state.jitter_min
    computed_time = round(current_time * percent_to_add) + current_time

    # Cap that to a jittered min and max
    percent_of_max = :rand.uniform() * (state.jitter_max - state.jitter_min) + state.jitter_min
    computed_time = if computed_time > max_time, do: round(max_time * percent_of_max), else: computed_time

    new_state = %{state | retry_ms: computed_time}
    {computed_time, new_state}
  end

  # do the initial sync of the resource type and add found resources to state
  defp fetch_initial(
         %State{resource_type: resource_type, table_name: table_name, conn: conn, client: client, runner: runner} = state
       ) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)

    op = client.list(api_version, kind, namespace: :all)

    case client.stream(conn, op) do
      {:ok, list_res} ->
        # Now it's possible that the list returns a {:error, _} tuple
        # Filter those out.
        # Push everything else remaining into kubestate but don't announce anything.
        # This might miss some anouncements between process restarts.
        list_res
        |> Enum.map(fn r -> clean(r, state) end)
        |> Enum.reject(&(&1 == nil))
        |> Enum.each(fn r ->
          # Push in what's there now.
          # but
          runner.add(table_name, r, skip_broadcast: true)
        end)

        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # set up watch on resource type
  defp watch(%{resource_type: resource_type, conn: conn, client: client} = state) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)
    op = client.watch(api_version, kind, namespace: :all)

    case client.stream(conn, op) do
      {:ok, watch_stream} ->
        Enum.each(watch_stream, &handle_watch_event(&1, state))

        {:ok, state}

      # core resource deprecated then removed
      {:error, %{message: "the server could not find the requested resource"}} ->
        # NOTE(jdt): we'll probably need a way to handle deprecations and version skew if we can be launched into arbitrary EKS clusters
        # e.g. PSP is deprecated and removed in 1.25 but available in 1.24. AWS still supports 1.24 until Jan 31 2025
        Logger.warning("Stopping watch on #{resource_type} as it appears to be removed in this version.")
        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_watch_event(
         %{"type" => "ADDED", "object" => object},
         %{table_name: state_table_name, runner: runner} = state
       ) do
    runner.add(state_table_name, clean(object, state))
  end

  defp handle_watch_event(
         %{"type" => "DELETED", "object" => object},
         %{table_name: state_table_name, runner: runner} = state
       ) do
    runner.delete(state_table_name, clean(object, state))
  end

  defp handle_watch_event(
         %{"type" => "MODIFIED", "object" => object},
         %{table_name: state_table_name, runner: runner} = state
       ) do
    runner.update(state_table_name, clean(object, state))
  end

  defp handle_watch_event(event, %{table_name: state_table_name} = _state) do
    Logger.warning("Unknown watch event #{inspect(event)} in #{inspect(state_table_name)}")
  end

  defp clean({:error, _}, _), do: nil

  defp clean(resource, %{resource_type: resource_type} = state) when is_map(resource) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)

    resource
    |> Map.put_new("apiVersion", api_version)
    |> Map.put_new("kind", kind)
    |> clean_inner(state)
  end

  # For Secrets and ConfigMaps we only want to keep the keys of the data field
  # This greatly decrease the data size and doesn't change sync behavior since
  # we rely on sha annotaions.
  defp clean_inner(resource, %{resource_type: resource_type}) when resource_type in [:config_map, :secret] do
    resource
    |> Map.put_new("data", Map.get(resource, "data", %{}))
    |> update_in(~w(data), fn data ->
      Map.new(data, fn {k, _v} -> {k, nil} end)
    end)
  end

  # Everything else we keep the resource as is.
  defp clean_inner(resource, _state) do
    resource
  end
end
