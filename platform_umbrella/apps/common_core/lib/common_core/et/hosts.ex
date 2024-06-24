defmodule CommonCore.ET.URLs do
  @moduledoc false
  alias CommonCore.Batteries.BatteryCoreConfig

  @local_home "http://home.backend-service.127-0-0-1.ip.batteriesincl.com:4100/api/v1"
  @prod_home "https://home.prod.batteriesincl.com/api/v1"

  def home_base_url(%BatteryCoreConfig{} = config) do
    if config.server_in_cluster do
      @prod_home
    else
      @local_home
    end
  end

  def usage_report_path(state_summary) do
    "/installations/#{install_id(state_summary)}/usage_reports"
  end

  def host_reports_path(state_summary) do
    "/installations/#{install_id(state_summary)}/host_reports"
  end

  def status_path(state_summary) do
    "/installations/#{install_id(state_summary)}/status"
  end

  defp install_id(state_summary) do
    CommonCore.StateSummary.Core.config_field(state_summary, :install_id)
  end
end
