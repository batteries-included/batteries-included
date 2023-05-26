defmodule KubeServices.SnapshotApply do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      KubeServices.SnapshotApply.InitialLaunchTask,
      KubeServices.SnapshotApply.FailedLauncher,
      KubeServices.SnapshotApply.EventLauncher,
      KubeServices.SnapshotApply.KubeApply
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
