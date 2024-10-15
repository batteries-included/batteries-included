defmodule CommonCore.ET.URLs do
  @moduledoc false
  alias CommonCore.Batteries.BatteryCoreConfig

  @local_home "http://home.127-0-0-1.batrsinc.co:4100/api/v1"
  @prod_home "https://home.batteriesincl.com/api/v1"
  @bi_home "http://home-base.battery-traditional.svc.cluster.local.:4000/api/v1"

  def home_base_url(%BatteryCoreConfig{usage: usage} = _config) when usage in [:internal_prod, :internal_int_test],
    do: @bi_home

  def home_base_url(%BatteryCoreConfig{usage: usage} = _config) when usage in [:internal_dev], do: @local_home

  def home_base_url(%BatteryCoreConfig{} = _config), do: @prod_home

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
