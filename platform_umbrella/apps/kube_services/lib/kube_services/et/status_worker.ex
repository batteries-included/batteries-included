defmodule KubeServices.ET.InstallStatusWorker do
  @moduledoc false

  use GenServer
  use TypedStruct

  alias CommonCore.ET.InstallStatus
  alias KubeServices.ET.HomeBaseClient

  require Logger

  typedstruct module: State do
    field :sleep_time, integer()
    field :home_client, pid() | atom(), default: HomeBaseClient
    field :last_status, CommonCore.ET.InstallStatus.t(), default: nil
  end

  @state_opts ~w(sleep_time home_client_pid)a

  @max_sleep_time 11 * 60 * 1000
  @min_sleep_time 10 * 60 * 1000

  @impl GenServer
  @spec init(keyword()) :: {:ok, State.t()}
  def init(args \\ []) do
    min_sleep_time = Keyword.get(args, :min_sleep_time, @min_sleep_time)
    max_sleep_time = Keyword.get(args, :max_sleep_time, @max_sleep_time)

    sleep_time = :rand.uniform(max_sleep_time - min_sleep_time) + min_sleep_time
    home_client = Keyword.get(args, :home_client, HomeBaseClient)

    state = struct!(State, sleep_time: sleep_time, home_client: home_client)

    _ = schedule_inital_report(state)
    {:ok, state}
  end

  @spec start_link(Keyword.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    {state_opts, opts} = Keyword.split(opts, @state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  @spec get_status(atom() | pid() | {atom(), any()}) :: CommonCore.ET.InstallStatus.t()
  def get_status(client \\ __MODULE__) do
    GenServer.call(client, :get_status)
  end

  defp schedule_report(%State{sleep_time: sleep_time} = _state) do
    Process.send_after(self(), :report, sleep_time)
  end

  defp schedule_inital_report(%State{sleep_time: _} = _state) do
    Process.send_after(self(), :report, :rand.uniform(90) + 10)
  end

  @impl GenServer
  def handle_info(:report, state) do
    Logger.info("Checking on the status of the installation")
    status_result = HomeBaseClient.get_status(state.home_client)
    _ = schedule_report(state)

    case status_result do
      {:ok, status} ->
        Logger.info("Status of the installation is #{inspect(status)}")
        {:noreply, %{state | last_status: status}}

      {:error, error} ->
        Logger.error("Error checking the status of the installation: #{inspect(error)}")
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_call(:get_status, _from, %{last_status: status} = state) do
    {:reply, status || InstallStatus.new!(status: :unknown), state}
  end
end
