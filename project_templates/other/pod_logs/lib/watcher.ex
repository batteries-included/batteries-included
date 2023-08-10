defmodule PodLogs.Watcher do
  require Logger
  use GenServer

  defmodule State do
    defstruct api_version: nil, kind: nil, connection: nil
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(args) do
    api_version = Keyword.fetch!(args, :api_version)
    kind = Keyword.fetch!(args, :kind)
    connection = Keyword.fetch!(args, :connection)

    Process.send_after(self(), :start_watch, 50)

    state = %State{
      api_version: api_version,
      kind: kind,
      connection: connection
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info(
        :start_watch,
        %State{api_version: api_ver, kind: kind, connection: conn} = state
      ) do
    op = K8s.Client.watch(api_ver, kind, namespace: :all)

    case K8s.Client.stream(conn, op) do
      {:ok, watch_stream} ->
        Enum.each(watch_stream, fn _event ->
          Logger.info("Message Recieved")
        end)

        :ok

      _ ->
        watch_delay = Map.get_lazy(state, :watch_delay, fn -> 500 + Enum.random(1..1000) end)
        {:delay, Process.send_after(self(), :start_watch, watch_delay)}
    end

    {:noreply, state}
  end
end
