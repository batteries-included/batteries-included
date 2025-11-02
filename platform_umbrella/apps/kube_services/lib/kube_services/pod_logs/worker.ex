defmodule KubeServices.PodLogs.Worker do
  @moduledoc """
  Handles K8s pod logs.

  Connects to pod/logs endpoint and sends stdout log lines to the target pid.
  """
  use TypedStruct
  use GenServer

  alias CommonCore.ApiVersionKind

  require Logger

  @get_opts ~w|name namespace container|a
  @state_opts ~w|opts conn connection_func target client|a

  typedstruct module: State do
    field :opts, keyword()
    field :conn, K8s.Conn.t() | nil
    field :connection_func, any()
    field :target, pid(), enforce: false

    # For mocking
    field :client, module(), default: CommonCore.K8s.Client

    def new!(opts) do
      {get_args, other_args} = Keyword.split(opts, ~w|name namespace container|a)
      # These are the required arguments that should be passed in as keyword lists.
      pid = Keyword.get(other_args, :target, nil)

      # Optional argument. Use the default connection pool if not specified.
      connection_func =
        Keyword.get(other_args, :connection_func, &CommonCore.ConnectionPool.get!/0)

      struct!(
        __MODULE__,
        other_args
        |> Keyword.put(:opts, get_args)
        |> Keyword.put(:connection_func, connection_func)
        |> Keyword.put(:target, pid)
      )
    end
  end

  def start_link(args) do
    {state_opts, gen_opts} = Keyword.split(args, @state_opts ++ @get_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  @impl GenServer
  def init(args) do
    # Create the inital state with conn being nil explictly
    # to allow for a lazy connection inside of `handle_info(:start_connect, state)`
    args = Keyword.put(args, :conn, nil)
    state = State.new!(args)
    Process.send_after(self(), :start_connect, 50)

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:start_connect, %State{opts: opts, client: client} = state) do
    conn = connection(state)

    {api_version, _kind} = ApiVersionKind.from_resource_type(:pod)

    # Kubernetes expects name and namespace on the path.
    # Other options should be in the query params or this fails.
    {main_opts, others} = Keyword.split(opts, [:name, :namespace])

    # However we know some of the query params are
    # always needed so add those here.
    query_params =
      Keyword.merge(others,
        # No previous lines
        tailLines: 0,
        # But we do want to continue following.
        # This param combined with using `K8s.Client.connect()`
        # is what allow this genserver to work.
        follow: true
      )

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
    # We can then receive each log line in `handle_info({:stdout, data}, state)`
    # where we do what we want with it.
    #
    # For now that's forward clean the line up and send it on.
    # TODO: send this to a phoenix pubsub from `event_center`
    {:ok, _} =
      api_version
      |> client.connect(
        "pods/log",
        main_opts,
        query_params
      )
      |> client.put_conn(conn)
      |> client.stream_to(self())

    {:noreply, %{state | conn: conn}}
  end

  @impl GenServer
  def handle_info({:open, true}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:stdout, _}, %State{target: nil} = state) do
    # If there's no target
    # Don't to anything
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:stdout, data}, %State{target: pid} = state) do
    # This is a single line from the stdout logs
    # Clean them up then send them on.
    message = {:pod_log, String.trim(data)}
    send(pid, message)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:close, _reason}, state) do
    # This means that the steam stopped
    # For now we just ignore this and
    # assume that the pod was deleted.
    #
    # We might want to :stop
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_other_msg, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:stop_please, state) do
    {:stop, :normal, state}
  end

  # memoize connection
  # TODO(jdt): maybe pull this out into a separate module as it's duplicated a few times
  def connection(%State{conn: conn} = _state) when not is_nil(conn), do: conn
  def connection(%State{connection_func: connection_func} = _state), do: connection_func.()
end
