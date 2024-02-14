defmodule CommonCore.StateSummary.URLs do
  @moduledoc false

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.Hosts

  @spec uri_for_battery(StateSummary.t(), atom()) :: URI.t()
  def uri_for_battery(state, battery) do
    "http://#{Hosts.for_battery(state, battery)}"
    |> URI.new!()
    |> then(fn uri ->
      if Batteries.batteries_installed?(state, :cert_manager), do: %URI{uri | scheme: "https", port: 443}, else: uri
    end)
  end

  @spec keycloak_uri_for_realm(StateSummary.t(), String.t()) :: URI.t()
  def keycloak_uri_for_realm(state, realm) do
    state
    |> uri_for_battery(:keycloak)
    |> URI.append_path("/realms/#{realm}")
  end

  def keycloak_console_uri_for_realm(state, realm) do
    state
    |> uri_for_battery(:keycloak)
    |> URI.append_path("/admin/#{realm}/console")
  end

  @spec cloud_native_pg_dashboard(CommonCore.StateSummary.t()) :: URI.t()
  def cloud_native_pg_dashboard(state) do
    state
    |> uri_for_battery(:grafana)
    |> URI.append_path("/d/cloudnative-pg/cloudnativepg")
  end

  @spec pod_dashboard(CommonCore.StateSummary.t()) :: URI.t()
  def pod_dashboard(state) do
    state
    |> uri_for_battery(:grafana)
    |> URI.append_path("/d/k8s_views_pods/kubernetes-views-pods")
  end
end
