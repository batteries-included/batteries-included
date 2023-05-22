defmodule KubeServices.SnapshotApply.FailedLauncher do
  use GenServer

  require Logger

  alias ControlServer.SnapshotApply.KubeSnapshot
  alias EventCenter.KubeSnapshot.Payload
  alias KubeServices.SnapshotApply.Worker

  defmodule State do
    defstruct delay: 5000, initial_delay: 5000, max_delay: 600_000, timer_reference: nil
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def handle_info(:start_apply, state) do
    job = Worker.start!()
    Logger.info("Starting job #{job.id} to retry failed snapshot apply", id: job.id)
    {:noreply, %State{state | timer_reference: nil}}
  end

  def handle_info(%Payload{snapshot: %KubeSnapshot{status: :error}} = _payload, state) do
    {:noreply, schedule_start(state)}
  end

  def handle_info(%Payload{snapshot: %KubeSnapshot{status: :ok}} = _payload, state) do
    {:noreply, reset_delay(state)}
  end

  def handle_info(%Payload{snapshot: _} = _payload, state) do
    # In progress snapshot apply, ignore until it's a terminal status
    {:noreply, state}
  end

  defp schedule_start(%State{timer_reference: nil, max_delay: max_delay, delay: delay} = state) do
    new_delay = min(max_delay, delay * 2)
    Logger.warning("After a failed snapshot scheduling the next retry in #{new_delay}")

    %State{
      state
      | timer_reference: Process.send_after(self(), :start_apply, delay),
        delay: new_delay
    }
  end

  defp schedule_start(%State{timer_reference: _} = _state) do
    Logger.warn("Failed snapshot timer already running. Ignoring")
  end

  defp reset_delay(%State{initial_delay: init_delay} = state) do
    Logger.info("Resetting delay")
    %State{state | delay: init_delay}
  end

  def init(_args) do
    :ok = EventCenter.KubeSnapshot.subscribe()
    {:ok, %State{}}
  end
end
