defmodule KubeServices.SnapshotApply.TimedLauncher do
  use GenServer

  alias KubeServices.SnapshotApply.Launcher
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter

  require Logger

  @me __MODULE__

  def start_link(opts \\ []) do
    delay = Keyword.get(opts, :delay, 900 * 1000)
    failing_delay = Keyword.get(opts, :failing_delay, 10 * 1000)
    name = Keyword.get(opts, :name, @me)

    {:ok, pid} =
      result =
      GenServer.start_link(
        __MODULE__,
        %{
          delay: delay,
          failing_delay: failing_delay,
          status: :unknown,
          running: nil
        },
        name: name
      )

    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl true
  def init(state) do
    :ok = SnapshotEventCenter.subscribe()
    {:ok, schedule(state)}
  end

  @impl true
  def handle_info(:launch, state) do
    Logger.debug("Time since last snapshot elapsed, launching")

    # Start the
    Launcher.launch(listeners: [self()])
    {:noreply, schedule(state)}
  end

  @impl true
  def handle_info(%SnapshotEventCenter.Payload{snapshot: snapshot}, %{status: old_status} = state) do
    if snapshot.status != old_status do
      Logger.info("Setting a new TimedLauncher status #{inspect(snapshot.status)}")
      {:noreply, %{state | status: snapshot.status} |> cancel_send() |> schedule()}
    else
      Logger.debug("Status remains the same skipping")
      {:noreply, state}
    end
  end

  defp schedule(state) do
    running = Process.send_after(self(), :launch, delay_time(state))
    %{state | running: running}
  end

  defp delay_time(%{status: :success, delay: delay}), do: delay
  defp delay_time(%{status: :ok, delay: delay}), do: delay
  defp delay_time(%{status: _, failing_delay: failing_delay}), do: failing_delay

  defp cancel_send(%{running: nil} = state), do: state

  defp cancel_send(%{running: running} = state) do
    result = Process.cancel_timer(running)
    Logger.info("Canceled timer #{inspect(running)} result = #{inspect(result)}")
    state
  end
end
