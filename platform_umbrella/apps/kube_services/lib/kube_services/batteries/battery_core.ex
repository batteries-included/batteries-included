defmodule KubeServices.Batteries.BatteryCore do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  def init(opts) do
    battery = Keyword.fetch!(opts, :battery)

    children = [
      {KubeServices.ET.HomeBaseClient,
       [
         home_url: CommonCore.ET.URLs.home_base_url(battery.config),
         control_jwk: battery.config.control_jwk,
         usage_report_path: CommonCore.ET.URLs.usage_report_path(battery.config),
         host_report_path: CommonCore.ET.URLs.host_reports_path(battery.config),
         status_path: CommonCore.ET.URLs.status_path(battery.config),
         stable_versions_path: CommonCore.ET.URLs.stable_versions_path(battery.config)
       ]},
      {KubeServices.ET.Usage, [home_client_pid: KubeServices.ET.HomeBaseClient]},
      {KubeServices.ET.Hosts, [home_client_pid: KubeServices.ET.HomeBaseClient]},
      {KubeServices.ET.InstallStatusWorker,
       [home_client_pid: KubeServices.ET.HomeBaseClient, install_id: battery.config.install_id]},
      {KubeServices.ET.StableVersionsWorker, [home_client_pid: KubeServices.ET.HomeBaseClient]},
      KubeServices.SystemState,
      KubeServices.SnapshotApply,
      KubeServices.Stale.Reaper,
      KubeServices.ResourceDeleter
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
