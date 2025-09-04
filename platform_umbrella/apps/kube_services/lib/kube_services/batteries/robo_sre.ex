defmodule KubeServices.Batteries.RoboSRE do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    battery = Keyword.fetch!(opts, :battery)

    children = [
      {KubeServices.RoboSRE.DynamicSupervisor, battery: battery},
      {KubeServices.RoboSRE.IssueWatcher, battery: battery}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
