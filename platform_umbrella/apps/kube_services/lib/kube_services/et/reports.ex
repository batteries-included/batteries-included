defmodule KubeServices.ET.Reports do
  @moduledoc """
  ET phones home to report.
  """
  use GenServer
  use TypedStruct

  require Logger

  typedstruct module: State do
    field :sleep_time, integer()
    field :send_func, fun()
    field :type, String.t()
  end

  @state_opts ~w(sleep_time send_func type)a

  @spec init() :: {:ok, struct()}
  def init(args \\ []) do
    min_sleep_time = Keyword.get(args, :min_sleep_time, 3 * 60 * 1000)
    max_sleep_time = Keyword.get(args, :max_sleep_time, 5 * 60 * 1000)
    send_func = Keyword.fetch!(args, :send_func)
    type = Keyword.fetch!(args, :type)

    sleep_time = :rand.uniform(max_sleep_time - min_sleep_time) + min_sleep_time

    state = struct!(State, sleep_time: sleep_time, send_func: send_func, type: type)

    _ = schedule_report(state)
    {:ok, state}
  end

  @spec start_link(Keyword.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    {init_args, genserver_opts} = opts |> Keyword.put_new(:name, __MODULE__) |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, init_args, genserver_opts)
  end

  defp schedule_report(%State{sleep_time: sleep_time} = _state) do
    Process.send_after(self(), :report, sleep_time)
  end

  def handle_info(:report, state) do
    Logger.info("Reporting #{state.type}")

    resp = send(state)
    Logger.info(inspect(resp))

    # Finally re-schedule the next report
    _ = schedule_report(state)
    {:noreply, state}
  end

  defp send(%State{send_func: send_func, type: type} = _state) do
    state_summary = KubeServices.SystemState.Summarizer.new()

    case send_func.(state_summary) do
      :ok ->
        :ok

      {:error, err} ->
        Logger.error("Failed to send #{type} report: #{inspect(err)}")
        {:error, err}

      unknown_error ->
        Logger.error("Failed to send #{type} report: #{inspect(unknown_error)}")
        {:error, {:unknown_error, unknown_error}}
    end
  end
end
