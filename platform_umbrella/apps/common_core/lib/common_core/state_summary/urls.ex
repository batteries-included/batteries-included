defmodule CommonCore.StateSummary.URLs do
  @moduledoc false

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Hosts
  alias CommonCore.StateSummary.SSL

  @spec uri_for_battery(StateSummary.t(), atom()) :: URI.t()
  def uri_for_battery(state, battery) do
    "http://#{Hosts.for_battery(state, battery)}"
    |> URI.new!()
    |> then(fn uri ->
      if SSL.ssl_enabled?(state), do: %URI{uri | scheme: "https", port: 443}, else: uri
    end)
  end

  @spec keycloak_uri_for_realm(StateSummary.t(), String.t()) :: URI.t()
  def keycloak_uri_for_realm(state, realm) do
    state
    |> uri_for_battery(:keycloak)
    |> URI.append_path("/realms/#{realm}")
  end

  @spec keycloak_console_uri_for_realm(StateSummary.t(), String.t()) :: URI.t()
  def keycloak_console_uri_for_realm(state, realm) do
    state
    |> uri_for_battery(:keycloak)
    |> URI.append_path("/admin/#{realm}/console")
  end

  @spec project_dashboard(StateSummary.t()) :: URI.t()
  def project_dashboard(state) do
    state
    |> uri_for_battery(:grafana)
    |> URI.append_path("/d/projects/projects")
  end

  @spec cloud_native_pg_dashboard(StateSummary.t()) :: URI.t()
  def cloud_native_pg_dashboard(state) do
    state
    |> uri_for_battery(:grafana)
    |> URI.append_path("/d/cloudnative-pg/cloudnativepg")
  end

  @spec pod_dashboard(StateSummary.t()) :: URI.t()
  def pod_dashboard(state) do
    state
    |> uri_for_battery(:grafana)
    |> URI.append_path("/d/k8s_views_pods/kubernetes-views-pods")
  end

  @spec knative_url(StateSummary.t(), CommonCore.Knative.Service.t()) :: URI.t()
  def knative_url(state, service) do
    "http://#{Hosts.knative_host(state, service)}"
    |> URI.new!()
    |> then(fn uri ->
      if SSL.ssl_enabled?(state), do: %URI{uri | scheme: "https", port: 443}, else: uri
    end)
  end
end
