defmodule KubeServices.SnapshotApply.EventLauncher do
  use GenServer
  use TypedStruct

  alias KubeServices.SnapshotApply.Worker

  require Logger

  @delay 2000

  typedstruct module: State do
    field :timer_reference, reference() | nil, default: nil
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Enum.each(
      [:jupyter_notebook, :knative_service, :postgres_cluster, :redis_cluster],
      &EventCenter.Database.subscribe/1
    )

    {:ok, struct!(State, opts)}
  end

  def handle_info({_action, _object}, %State{timer_reference: ref} = state) do
    Logger.debug("Database event received, scheduling creation", state: state)
    {:noreply, %State{state | timer_reference: schedule_start(ref)}}
  end

  def handle_info(:do_start_creation, state) do
    _ = Worker.start()
    {:noreply, %State{state | timer_reference: nil}}
  end

  @spec schedule_start(reference() | nil) :: reference()
  defp schedule_start(nil = _current_reference),
    do: Process.send_after(self(), :do_start_creation, @delay)

  defp schedule_start(current_reference), do: current_reference
end
