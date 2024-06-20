defmodule KubeServices.Batteries.BatteryCore do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    battery = Keyword.fetch!(opts, :battery)

    children = [
      KubeServices.SnapshotApply,
      KubeServices.Stale.Reaper,
      KubeServices.ResourceDeleter,
      {KubeServices.ET.HomeBaseClient, [home_url: CommonCore.ET.URLs.home_base_url(battery.config)]},
      {KubeServices.ET.Usage, [home_client_pid: KubeServices.ET.HomeBaseClient]},
      {KubeServices.ET.Hosts, [home_client_pid: KubeServices.ET.HomeBaseClient]},
      {KubeServices.ET.InstallStatusWorker,
       [home_client_pid: KubeServices.ET.HomeBaseClient, install_id: battery.config.install_id]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
