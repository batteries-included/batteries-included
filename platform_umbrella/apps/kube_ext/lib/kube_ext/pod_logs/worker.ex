defmodule KubeExt.PodLogs.Worker do
  use GenServer

  alias CommonCore.ApiVersionKind

  require Logger

  defmodule State do
    defstruct namespace: nil, name: nil, conn: nil, connection_func: nil, target: nil
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    # These are the required arguments that should be passed in as keyword lists.
    namespace = Keyword.fetch!(args, :namespace)
    name = Keyword.fetch!(args, :name)
    pid = Keyword.fetch!(args, :target)

    # Optional argument. Use the default connection pool if not specified.
    connection_func = Keyword.get(args, :connection_func, &KubeExt.ConnectionPool.get/0)

    Process.send_after(self(), :start_connect, 50)

    # Create the inital state with conn being nil explictly
    # to allow for a lazy connection inside of `handle_info(:start_connect, ctx)`
    state = %State{
      namespace: namespace,
      name: name,
      connection_func: connection_func,
      conn: nil,
      target: pid
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:start_connect, %State{namespace: namespace, name: name} = state) do
    conn = connection(state)

    {api_version, _kind} = ApiVersionKind.from_resource_type(:pod)

    # Start a K8s connection operation
    # (not to be confused with an actual connection)
    # Then configure it to stream to this process.
    #
    # Under the hood `K8s.Client` will get a stream of
    # binary by opening a websocket stream with the correct
    # path, params, and verbs such that
    # each entry is a single string line from the stdout
    # logs of a pod. Since we've configured `stream_to`
    # `K8s` will `&send/2` that log line to this process.
    #
    # We can then receive each log line in `handle_info({:stdout, data}, ctx)`
    # where we do what we want with it.
    #
    # For now that's forward clean the line up and send it on.
    # TODO: send this to a phoenix pubsub from `event_center`
    {:ok, _} =
      K8s.Client.connect(
        api_version,
        "pods/log",
        [namespace: namespace, name: name],
        # No previous lines
        tailLines: 0,
        # But we do want to continue following.
        # This param combined with using `K8s.Client.connect()`
        # is what allow this genserver to work.
        follow: true
      )
      |> K8s.Client.put_conn(conn)
      |> K8s.Client.stream_to(self())

    {:noreply, %State{state | conn: conn}}
  end

  @impl GenServer
  def handle_info({:open, true}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:stdout, data}, %State{target: pid} = ctx) do
    # This is a single line from the stdout logs
    # Clean them up then send them on.
    message = {:pod_log, String.trim(data)}
    send(pid, message)
    {:noreply, ctx}
  end

  @impl GenServer
  def handle_info({:close, _reason}, ctx) do
    # This means that the steam stopped
    # For now we just ignore this and
    # assume that the pod was deleted.
    #
    # We might want to :stop
    {:noreply, ctx}
  end

  @impl GenServer
  def handle_info(_other_msg, ctx) do
    {:noreply, ctx}
  end

  def connection(%State{conn: conn} = _state) when not is_nil(conn), do: conn
  def connection(%State{connection_func: connection_func} = _state), do: connection_func.()
end
