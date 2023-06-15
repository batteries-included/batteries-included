defmodule KubeServices.SnapshotApply do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      KubeServices.SnapshotApply.KubeApply,
      KubeServices.SnapshotApply.Worker,
      KubeServices.SnapshotApply.FailedKubeLauncher,
      KubeServices.SnapshotApply.EventLauncher
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
