defmodule KubeServices.Batteries.BatteryCore do
  @moduledoc false
  use KubeServices.Batteries.Supervisor

  alias CommonCore.ET.URLs
  alias KubeServices.ET.HomeBaseClient

  require Logger

  def init(opts) do
    battery = Keyword.fetch!(opts, :battery)

    children = [
      {HomeBaseClient,
       [
         home_url: URLs.home_base_url(battery.config),
         control_jwk: battery.config.control_jwk,
         usage_report_path: URLs.usage_report_path(battery.config),
         host_report_path: URLs.host_reports_path(battery.config),
         status_path: URLs.status_path(battery.config),
         stable_versions_path: URLs.stable_versions_path(battery.config),
         project_snapshot_path: URLs.project_snapshot_path(battery.config)
       ]},
      {KubeServices.ET.Usage, [home_client_pid: HomeBaseClient]},
      {KubeServices.ET.Hosts, [home_client_pid: HomeBaseClient]},
      {KubeServices.ET.InstallStatusWorker, [home_client_pid: HomeBaseClient, install_id: battery.config.install_id]},
      {KubeServices.ET.StableVersionsWorker, [home_client_pid: HomeBaseClient]},
      KubeServices.SystemState,
      KubeServices.SnapshotApply,
      KubeServices.ResourceDeleter
    ]

    Logger.debug("Starting BatteryCore")

    Supervisor.init(children, strategy: :one_for_one)
  end
end
