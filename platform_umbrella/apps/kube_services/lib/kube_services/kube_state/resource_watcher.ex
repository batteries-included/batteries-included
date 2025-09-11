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
  alias KubeServices.K8s.Client
  alias KubeServices.KubeState.Runner

  require Logger

  typedstruct module: State do
    field :resource_type, atom(), enforce: true
    field :table_name, atom(), enforce: true

    field :conn, K8s.Conn.t() | nil
    field :connection_func, (-> K8s.Conn.t()), enforce: true

    field :watch_delay, non_neg_integer(), default: 100

    field :retries, non_neg_integer(), default: 0
    field :max_retries, non_neg_integer(), default: 14
    field :retry_ms, non_neg_integer(), default: 6000
    field :jitter_min, float(), default: 0.75
    field :jitter_max, float(), default: 1.25

    # For mocking
    field :client, module(), default: Client
    field :runner, module(), default: Runner

    def new!(opts) do
      struct!(__MODULE__, opts)
    end
  end

  @state_opts ~w(resource_type client conn connection_func watch_delay table_name client runner)a

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

    trigger_start_watch(state)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:start_watch, state) do
    {:noreply, start_watch(state)}
  end

  defp trigger_start_watch(
         %{watch_delay: delay, jitter_min: jitter_min, jitter_max: jitter_max, retries: retries, retry_ms: retry_ms} =
           _state
       ) do
    delay = delay + retries * retry_ms

    # random time between 75% to 125% of delay
    min = floor(jitter_min * delay)
    max = ceil(jitter_max * delay)
    Process.send_after(self(), :start_watch, Enum.random(min..max))
  end

  defp start_watch(state) do
    # Finally inflate the connection here.
    # From now on we need to remember that in the state
    state = inflate_connection(state)
    state = fetch_initial(state)

    # watch. While this doesn't plumb through resource version
    # It's good enough for now.
    case watch(state) do
      :ok ->
        %{state | retries: 1}

      {:delay, _ref} ->
        %{state | retries: min(state.retries + 1, state.max_retries)}
    end
  end

  # do the initial sync of the resource type and add found resources to state
  defp fetch_initial(
         %{resource_type: resource_type, table_name: table_name, conn: conn, client: client, runner: runner} = state
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

      _ ->
        Logger.warning("Can't list for #{inspect(resource_type)} assuming there are none")
    end

    state
  end

  # set up watch on resource type
  defp watch(%{resource_type: resource_type, retries: retries, conn: conn, client: client} = state) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)
    op = client.watch(api_version, kind, namespace: :all)

    case client.stream(conn, op) do
      {:ok, watch_stream} ->
        Enum.each(watch_stream, fn event ->
          handle_watch_event(
            Map.get(event, "type", nil),
            Map.get(event, "object", nil),
            state
          )
        end)

        :ok

      # core resource deprecated then removed
      {:error, %{message: "the server could not find the requested resource"}} ->
        # NOTE(jdt): we'll probably need a way to handle deprecations and version skew if we can be launched into arbitrary EKS clusters
        # e.g. PSP is deprecated and removed in 1.25 but available in 1.24. AWS still supports 1.24 until Jan 31 2025
        Logger.warning("Stopping watch on #{resource_type} as it appears to be removed in this version.")
        {:delay, nil}

      _ ->
        # add 6 seconds per retry. the max is configured in `start_watch` where retries is incremented.
        {:delay, trigger_start_watch(%{state | retries: retries + 1})}
    end
  end

  defp handle_watch_event(event_type, object, state_table_name)

  defp handle_watch_event("ADDED" = _event_type, object, %{table_name: state_table_name, runner: runner} = state),
    do: runner.add(state_table_name, clean(object, state))

  defp handle_watch_event("DELETED" = _event_type, object, %{table_name: state_table_name, runner: runner} = state),
    do: runner.delete(state_table_name, clean(object, state))

  defp handle_watch_event("MODIFIED" = _event_type, object, %{table_name: state_table_name, runner: runner} = state),
    do: runner.update(state_table_name, clean(object, state))

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

  defp inflate_connection(%{conn: nil, connection_func: connection_func} = state) when is_function(connection_func) do
    conn = connection_func.()
    %{state | conn: conn}
  end

  defp inflate_connection(state), do: state
end
