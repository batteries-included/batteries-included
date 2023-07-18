defmodule KubeServices.Batteries.BatteryCore do
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    _battery = Keyword.fetch!(opts, :battery)

    children = [
      KubeServices.SnapshotApply,
      KubeServices.ResourceDeleter
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
