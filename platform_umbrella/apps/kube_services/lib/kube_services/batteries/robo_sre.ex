defmodule KubeServices.Batteries.RoboSRE do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    battery = Keyword.fetch!(opts, :battery)

    children = [
      KubeServices.RoboSRE.Registry,
      {KubeServices.RoboSRE.DynamicSupervisor, battery: battery},
      {KubeServices.RoboSRE.DeleteResourceExecutor, []},
      {KubeServices.RoboSRE.IssueWatcher, battery: battery},

      # Put General detectors/handlers here
      # Other batteries can run their own detectors/handlers too
      # under their own supervision tree. The ones here are
      # shared across all batteries, or from RoboSRE's dependencies
      {KubeServices.RoboSRE.StuckKubeStateHandler, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
