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

  require Logger

  @state_opts ~w(resource_type client conn watch_delay connection_func table_name)a

  @spec start_link(keyword) :: {:ok, pid}
  def start_link(opts) do
    {state_opts, gen_opts} = Keyword.split(opts, @state_opts)

    {:ok, pid} = result = GenServer.start_link(__MODULE__, state_opts, gen_opts)
    Logger.debug("GenServer started with# #{inspect(pid)}. #{inspect(gen_opts)}")
    result
  end

  @impl GenServer
  def init(opts) do
    watch_delay = Keyword.get_lazy(opts, :watch_delay, fn -> 500 + Enum.random(1..1000) end)
    Process.send_after(self(), :start_watch, watch_delay)
    {:ok, Map.new(opts)}
  end

  @impl GenServer
  def handle_info(:start_watch, state) do
    {:noreply, start_watch(state)}
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
        Map.put(state, :conn, conn)

      {:delay, _ref} ->
        state
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
        |> Enum.map(fn r -> clean(state, r) end)
        |> Enum.reject(&(&1 == nil))
        |> Enum.each(fn r ->
          # Push in what's there now.
          # but
          KubeServices.KubeState.Runner.add(table_name, r, skip_broadcast: true)
        end)

      _ ->
        Logger.warning("Can't list for #{inspect(resource_type)} assuming there are none")
    end

    state
  end

  # set up watch on resource type
  defp watch(%{resource_type: resource_type, table_name: table_name} = state, conn) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)
    op = K8s.Client.watch(api_version, kind, namespace: :all)

    case K8s.Client.stream(conn, op) do
      {:ok, watch_stream} ->
        Enum.each(watch_stream, fn event ->
          handle_watch_event(
            Map.get(event, "type", nil),
            Map.get(event, "object", nil),
            table_name
          )
        end)

        :ok

      _ ->
        # TODO(jdt): hoist this out of the watch fn and consolidate delay + jitter handling
        watch_delay = Map.get_lazy(state, :watch_delay, fn -> 500 + Enum.random(1..1000) end)
        {:delay, Process.send_after(self(), :start_watch, watch_delay)}
    end
  end

  defp handle_watch_event(event_type, object, state_table_name)

  defp handle_watch_event("ADDED" = _event_type, object, state_table_name),
    do: KubeServices.KubeState.Runner.add(state_table_name, object)

  defp handle_watch_event("DELETED" = _event_type, object, state_table_name),
    do: KubeServices.KubeState.Runner.delete(state_table_name, object)

  defp handle_watch_event("MODIFIED" = _event_type, object, state_table_name),
    do: KubeServices.KubeState.Runner.update(state_table_name, object)

  defp clean(_, {:error, _}), do: nil

  defp clean(%{resource_type: resource_type}, resource) when is_map(resource) do
    {api_version, kind} = ApiVersionKind.from_resource_type(resource_type)

    resource
    |> Map.put_new("apiVersion", api_version)
    |> Map.put_new("kind", kind)
  end

  # memoize connection fn
  defp connection(%{conn: conn} = _state), do: conn
  defp connection(%{connection_func: connection_func} = _state), do: connection_func.()
end
