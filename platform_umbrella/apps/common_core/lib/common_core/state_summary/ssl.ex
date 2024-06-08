defmodule CommonCore.StateSummary.SSL do
  @moduledoc false
  alias CommonCore.StateSummary

  @doc """
  Returns true if SSL is to access Control Server and other istio ingress fronted services.
  """
  def ssl_enabled?(state) do
    cert_manager_installed?(state) and !kind_cluster?(state)
  end

  defp kind_cluster?(state) do
    :kind == StateSummary.Core.config_field(state, :cluster_type)
  end

  defp cert_manager_installed?(state) do
    CommonCore.StateSummary.Batteries.batteries_installed?(state, :cert_manager)
  end
end
