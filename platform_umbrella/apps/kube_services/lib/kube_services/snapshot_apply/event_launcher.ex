defmodule KubeServices.SnapshotApply.EventLauncher do
  use GenServer

  alias KubeServices.SnapshotApply.CreationWorker

  require Logger

  @delay 2000

  defmodule State do
    defstruct timer_reference: nil
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Enum.each(
      [:jupyter_notebook, :knative_service, :postgres_cluster, :redis_cluster, :system_battery],
      &EventCenter.Database.subscribe/1
    )

    {:ok, struct!(State, opts)}
  end

  def handle_info({_action, _object}, %State{timer_reference: ref} = state) do
    Logger.debug("XX got message might start job", state: state)
    {:noreply, %State{state | timer_reference: schedule_start(ref)}}
  end

  def handle_info(:do_start_creation, state) do
    job = CreationWorker.start!()
    Logger.info("XX Starting job #{job.id}", id: job.id)
    {:noreply, %State{state | timer_reference: nil}}
  end

  defp schedule_start(nil = _current_reference),
    do: Process.send_after(self(), :do_start_creation, @delay)

  defp schedule_start(current_reference), do: current_reference
end
