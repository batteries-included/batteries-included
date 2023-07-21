defmodule PodLogs.Worker do
  use GenServer

  require Logger

  defmodule State do
    defstruct namespace: nil, name: nil
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    # These are the required arguments that should be passed in as keyword lists.
    namespace = Keyword.fetch!(args, :namespace)
    name = Keyword.fetch!(args, :name)

    Process.send_after(self(), :start_connect, 50)

    # Create the inital state with conn being nil explictly
    # to allow for a lazy connection inside of `handle_info(:start_connect, ctx)`
    state = %State{
      namespace: namespace,
      name: name
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(:start_connect, %State{namespace: namespace, name: name} = state) do
    api_version = "v1"
    {:ok, conn} = K8s.Conn.from_file("~/.kube/config", insecure_skip_tls_verify: true)

    {:ok, _} =
      K8s.Client.connect(
        api_version,
        "pods/log",
        [namespace: namespace, name: name],
        tailLines: 0,
        follow: true
      )
      |> K8s.Client.put_conn(conn)
      |> K8s.Client.stream_to(self())

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:open, true}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:stdout, data}, ctx) do
    Logger.info(data)
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
end
