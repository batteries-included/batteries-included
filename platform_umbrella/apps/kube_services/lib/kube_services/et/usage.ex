defmodule KubeServices.ET.Usage do
  @moduledoc """
  ET phones home to report usage statistics.
  """
  use GenServer
  use TypedStruct

  alias KubeServices.ET.HomeBaseClient

  require Logger

  typedstruct module: State do
    field :sleep_time, integer()
    field :home_client, pid() | atom(), default: HomeBaseClient
  end

  @state_opts ~w(sleep_time home_client_pid)a

  @spec init() :: {:ok, struct()}
  def init(args \\ []) do
    min_sleep_time = Keyword.get(args, :min_sleep_time, 4 * 60 * 1000)
    max_sleep_time = Keyword.get(args, :max_sleep_time, 5 * 60 * 1000)

    sleep_time = :rand.uniform(max_sleep_time - min_sleep_time) + min_sleep_time
    home_client = Keyword.get(args, :home_client, HomeBaseClient)

    state = struct!(State, sleep_time: sleep_time, home_client: home_client)

    _ = schedule_report(state)
    {:ok, state}
  end

  @spec start_link(Keyword.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    {init_opts, opts} = Keyword.split(opts, @state_opts)

    GenServer.start_link(__MODULE__, init_opts, opts)
  end

  defp schedule_report(%State{sleep_time: sleep_time} = _state) do
    Process.send_after(self(), :report, sleep_time)
  end

  def handle_info(:report, state) do
    Logger.info("Reporting usage to #{state.home_client}")

    _ = schedule_report(state)

    # Send the usage report
    # Logging errors and unknown errors but
    # not stopping the process
    case send_usage(state) do
      :ok ->
        {:noreply, state}

      {:error, {:unknown_error, unknown_error}} ->
        Logger.error("Unknown error sending usage report: #{inspect(unknown_error)}")
        {:noreply, state}

      {:error, err} ->
        Logger.error("Error sending usage report: #{inspect(err)}")
        {:noreply, state}
    end
  end

  defp send_usage(%State{home_client: home_client} = _state) do
    state_summary = KubeServices.SystemState.Summarizer.new()

    case HomeBaseClient.send_usage(home_client, state_summary) do
      :ok ->
        :ok

      {:error, err} ->
        {:error, err}

      unknown_error ->
        {:error, {:unknown_error, unknown_error}}
    end
  end
end
