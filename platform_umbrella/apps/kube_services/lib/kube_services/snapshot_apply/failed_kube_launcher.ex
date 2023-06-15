defmodule KubeServices.SnapshotApply.FailedKubeLauncher do
  use GenServer
  use TypedStruct

  require Logger

  alias ControlServer.SnapshotApply.KubeSnapshot
  alias EventCenter.KubeSnapshot.Payload
  alias KubeServices.SnapshotApply.Worker

  typedstruct module: State do
    field :delay, non_neg_integer(), deafult: 5000
    field :initial_delay, non_neg_integer(), default: 5000
    field :max_delay, non_neg_integer(), default: 600_000
    field :timer_reference, reference() | nil, default: nil
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def handle_info(:start_apply, state) do
    _ = Worker.start()
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
    Logger.debug("Successful apply, resetting delay back to initial values #{init_delay}")
    %State{state | delay: init_delay}
  end

  def init(args) do
    :ok = EventCenter.KubeSnapshot.subscribe()
    {:ok, struct(State, args)}
  end
end
