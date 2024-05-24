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
      Supervisor.child_spec(
        {KubeServices.ET.Reports,
         [send_func: &CommonCore.ET.HomeBaseClient.send_hosts/1, type: :hosts, name: :reports_hosts]},
        id: :reports_hosts
      ),
      Supervisor.child_spec(
        {KubeServices.ET.Reports,
         [send_func: &CommonCore.ET.HomeBaseClient.send_usage/1, type: :usage, name: :reports_usage]},
        id: :reports_usage
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
