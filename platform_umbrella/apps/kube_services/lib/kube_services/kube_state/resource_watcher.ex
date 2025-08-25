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

  alias CommonCore.ApiVersionKind
  alias KubeServices.KubeState.Runner

  require Logger

  @defaults %{
    delay: 1000,
    retries: 0,
    max_retries: 14,
    retry_secs: 6,
    jitter_min: 0.75,
    jitter_max: 1.25
  }

  @state_opts ~w(resource_type client conn watch_delay connection_func table_name)a

  @spec start_link(keyword) :: GenServer.on_start()
  def start_link(opts) do
    {state_opts, gen_opts} = Keyword.split(opts, @state_opts)

    {:ok, pid} = result = GenServer.start_link(__MODULE__, state_opts, gen_opts)
    Logger.debug("GenServer started with #{inspect(pid)}. #{inspect(gen_opts)}")
    result
  end

  @impl GenServer
  def init(opts) do
    opts =
      opts
      |> Keyword.put_new(:watch_delay, @defaults.delay)
      |> Keyword.put(:retries, @defaults.retries)
      |> Map.new()

    trigger_start_watch(opts)

    {:ok, opts}
  end

  @impl GenServer
  def handle_info(:start_watch, state) do
    {:noreply, start_watch(state)}
  end

  defp trigger_start_watch(%{watch_delay: delay} = _state), do: trigger_start_watch(delay)

  defp trigger_start_watch(delay_ms) do
    # random time between 75% to 125% of delay
    min = floor(@defaults.jitter_min * delay_ms)
    max = ceil(@defaults.jitter_max * delay_ms)
    Process.send_after(self(), :start_watch, Enum.random(min..max))
  end

  defp start_watch(state) do
    # Finally inflate the connection here.
    # From now on we need to remember that in the state
    conn = connection(state)

    # get the inital state that's there
    state = fetch_initial(state, conn)

    # watch. While this doesn't plumb through resource version
    # It's good enough for now.
    case watch(state, conn) do
      :ok ->
        Map.merge(state, %{conn: conn, retries: 1})

      {:delay, _ref} ->
        %{state | retries: min(state.retries + 1, @defaults.max_retries)}
    end
  end

  # do the initial sync of the resource type and add found resources to state
  defp fetch_initial(%{resource_type: resource_type, table_name: table_name} = state, conn) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)

    op = K8s.Client.list(api_version, kind, namespace: :all)

    case K8s.Client.stream(conn, op) do
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
          Runner.add(table_name, r, skip_broadcast: true)
        end)

      _ ->
        Logger.warning("Can't list for #{inspect(resource_type)} assuming there are none")
    end

    state
  end

  # set up watch on resource type
  defp watch(%{resource_type: resource_type, retries: retries} = state, conn) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)
    op = K8s.Client.watch(api_version, kind, namespace: :all)

    case K8s.Client.stream(conn, op) do
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
        {:delay, trigger_start_watch((retries + 1) * @defaults.retry_secs * 1_000)}
    end
  end

  defp handle_watch_event(event_type, object, state_table_name)

  defp handle_watch_event("ADDED" = _event_type, object, %{table_name: state_table_name} = state),
    do: Runner.add(state_table_name, clean(object, state))

  defp handle_watch_event("DELETED" = _event_type, object, %{table_name: state_table_name} = state),
    do: Runner.delete(state_table_name, clean(object, state))

  defp handle_watch_event("MODIFIED" = _event_type, object, %{table_name: state_table_name} = state),
    do: Runner.update(state_table_name, clean(object, state))

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

  # memoize connection fn
  defp connection(%{conn: conn} = _state), do: conn
  defp connection(%{connection_func: connection_func} = _state), do: connection_func.()
end
