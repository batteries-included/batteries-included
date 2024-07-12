defmodule CommonCore.ET.URLs do
  @moduledoc false
  alias CommonCore.Batteries.BatteryCoreConfig

  @local_home "http://home.backend-service.127-0-0-1.batrsinc.co:4100/api/v1"
  @prod_home "https://home.prod.batteriesincl.com/api/v1"

  def home_base_url(%BatteryCoreConfig{} = config) do
    if config.server_in_cluster do
      @prod_home
    else
      @local_home
    end
  end

  def stable_versions_path(%BatteryCoreConfig{} = _config) do
    "/stable_versions"
  end

  def usage_report_path(%BatteryCoreConfig{} = config) do
    "/installations/#{config.install_id}/usage_reports"
  end

  def host_reports_path(%BatteryCoreConfig{} = config) do
    "/installations/#{config.install_id}/host_reports"
  end

  def status_path(%BatteryCoreConfig{} = config) do
    "/installations/#{config.install_id}/status"
  end
end
