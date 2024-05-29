defmodule KubeServices.Batteries.BatteryCore do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    battery = Keyword.fetch!(opts, :battery)

    children = [
      KubeServices.SnapshotApply,
      KubeServices.Stale.Reaper,
      KubeServices.ResourceDeleter,
      {CommonCore.ET.HomeBaseClient, [home_url: CommonCore.ET.URLs.home_base_url(battery.config)]},
      {KubeServices.ET.Usage, [home_client_pid: CommonCore.ET.HomeBaseClient]},
      {KubeServices.ET.Hosts, [home_client_pid: CommonCore.ET.HomeBaseClient]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
