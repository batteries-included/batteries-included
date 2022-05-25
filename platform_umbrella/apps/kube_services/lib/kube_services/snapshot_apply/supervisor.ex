defmodule KubeServices.SnapshotApply.Supervisor do
  use DynamicSupervisor

  alias KubeServices.SnapshotApply.State
  alias KubeServices.SnapshotApply.Worker
  alias KubeServices.SnapshotApply.ResourcePathWorker

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start(snapshot \\ nil) do
    {:ok, state_pid} = supervise_state_server(snapshot)
    {:ok, _} = supervise_worker_server(state_pid)
    {:ok, state_pid}
  end

  def start_resource_path(resource_path, worker_pid) do
    DynamicSupervisor.start_child(
      __MODULE__,
      ResourcePathWorker.child_spec([resource_path, worker_pid])
    )
  end

  defp supervise_state_server(snapshot) do
    DynamicSupervisor.start_child(__MODULE__, State.child_spec([snapshot]))
  end

  defp supervise_worker_server(state_pid) do
    DynamicSupervisor.start_child(__MODULE__, Worker.child_spec([state_pid]))
  end
end
