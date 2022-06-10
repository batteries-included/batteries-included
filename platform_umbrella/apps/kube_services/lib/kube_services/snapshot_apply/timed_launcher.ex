defmodule KubeServices.SnapshotApply.TimedLauncher do
  use GenServer

  alias KubeServices.SnapshotApply.Launcher
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter

  require Logger

  @me __MODULE__

  def start_link(opts \\ []) do
    delay = Keyword.get(opts, :delay, default_delay())
    failing_delay = Keyword.get(opts, :failing_delay, default_failing_delay())
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

  defp default_config, do: Application.get_env(:kube_services, __MODULE__)

  defp default_delay, do: Keyword.get(default_config(), :delay, 900_000)
  defp default_failing_delay, do: Keyword.get(default_config(), :failing_delay, 10_000)

  @impl true
  def init(state) do
    :ok = SnapshotEventCenter.subscribe()
    {:ok, schedule(state)}
  end

  @impl true
  def handle_info(:launch, state) do
    Logger.debug("Time since last snapshot elapsed, launching")

    # Send the message to the singleton actor.
    Launcher.launch()
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
