defmodule KubeServices.ET.InstallStatusWorker do
  @moduledoc false

  use GenServer
  use TypedStruct

  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.ET.InstallStatus
  alias KubeServices.ET.HomeBaseClient

  require Logger

  typedstruct module: State do
    field :sleep_time, integer()
    field :home_client, pid() | atom(), default: HomeBaseClient
    field :last_status, InstallStatus.t(), default: nil
    field :install_id, BatteryUUID.t(), default: nil
  end

  @state_opts ~w(sleep_time home_client_pid install_id)a

  @max_sleep_time 11 * 60 * 1000
  @min_sleep_time 10 * 60 * 1000

  @impl GenServer
  @spec init(keyword()) :: {:ok, State.t()}
  def init(args \\ []) do
    min_sleep_time = Keyword.get(args, :min_sleep_time, @min_sleep_time)
    max_sleep_time = Keyword.get(args, :max_sleep_time, @max_sleep_time)

    sleep_time = :rand.uniform(max_sleep_time - min_sleep_time) + min_sleep_time
    home_client = Keyword.get(args, :home_client, HomeBaseClient)

    state =
      struct!(State,
        sleep_time: sleep_time,
        home_client: home_client,
        install_id: Keyword.get(args, :install_id),
        last_status: InstallStatus.new_unknown!()
      )

    _ = schedule_inital_report(state)

    Logger.debug("Starting InstallStatusWorker with sleep time #{sleep_time} pid = #{inspect(self())}")

    {:ok, state}
  end

  @spec start_link(Keyword.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    {state_opts, opts} = Keyword.split(opts, @state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  @spec get_status(GenServer.server()) :: InstallStatus.t() | {:error, any()}
  def get_status(client \\ __MODULE__) do
    GenServer.call(client, :get_status)
  catch
    :exit, {:noproc, _} -> {:error, :not_started}
  end

  defp schedule_report(%State{sleep_time: sleep_time} = _state) do
    Process.send_after(self(), :report, sleep_time)
  end

  defp schedule_inital_report(%State{sleep_time: _} = _state) do
    Process.send_after(self(), :report, :rand.uniform(90) + 1500)
  end

  defp schedule_retry_report(%State{sleep_time: sleep_time} = _state) do
    min = Integer.floor_div(sleep_time, 5)
    Process.send_after(self(), :report, :rand.uniform(min) + min)
  end

  @impl GenServer
  def handle_info(:report, %{install_id: nil} = state) do
    Logger.info("No install_id was provided to the InstallStatusWorker")

    if state.last_status.status == :ok do
      {:noreply, %{state | last_status: InstallStatus.new_unknown!()}}
    else
      {:noreply, state}
    end
  end

  def handle_info(:report, %{install_id: install_id} = state) do
    Logger.info("Checking on the status of the installation")

    with {:ok, status} <- HomeBaseClient.get_status(state.home_client),
         {:ok, ^install_id} <- BatteryUUID.cast(status.iss) do
      _ = schedule_report(state)
      Logger.info("Status of the installation is #{inspect(status)}")
      {:noreply, %{state | last_status: status}}
    else
      {:error, error} ->
        Logger.error("Error checking the status of the installation: #{inspect(error)}")
        _ = schedule_retry_report(state)

        # If the previous status was not just `InstallStatus.status_ok?/1` but a
        # status that is explictlt something returned from the server and
        # good then default to unknown.
        #
        # If the previous status was bad then keep it bad.
        #
        # If it's unknown then keep it unknown with the timer running so it will timeout
        if state.last_status.status == :ok do
          {:noreply, %{state | last_status: InstallStatus.new_unknown!()}}
        else
          {:noreply, state}
        end

      unexpected ->
        Logger.error("Unexpected response from the server: #{inspect(unexpected)}")
        _ = schedule_retry_report(state)
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_call(:get_status, _from, %{last_status: status} = state) do
    {:reply, status, state}
  end
end
