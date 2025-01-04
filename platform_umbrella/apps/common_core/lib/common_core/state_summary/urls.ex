defmodule CommonCore.StateSummary.URLs do
  @moduledoc false

  alias CommonCore.Knative.Service
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Core
  alias CommonCore.StateSummary.Hosts
  alias CommonCore.StateSummary.SSL

  @spec uri_for_battery(StateSummary.t(), atom()) :: URI.t()
  def uri_for_battery(state, :battery_core) do
    if Core.config_field(state, :usage) == :internal_dev do
      URI.parse("http://control.127-0-0-1.batrsinc.co:4000/")
    else
      state
      |> Hosts.for_battery(:battery_core)
      |> build_uri(SSL.ssl_enabled?(state))
    end
  end

  def uri_for_battery(state, battery) do
    state
    |> Hosts.for_battery(battery)
    |> build_uri(SSL.ssl_enabled?(state))
  end

  @spec uris_for_battery(StateSummary.t(), atom()) :: list(URI.t())
  def uris_for_battery(state, :battery_core) do
    if Core.config_field(state, :usage) == :internal_dev do
      [URI.parse("http://control.127-0-0-1.batrsinc.co:4000/")]
    else
      state
      |> Hosts.hosts_for_battery(:battery_core)
      |> Enum.map(&build_uri(&1, SSL.ssl_enabled?(state)))
    end
  end

  def uris_for_battery(state, battery) do
    state
    |> Hosts.hosts_for_battery(battery)
    |> Enum.map(&build_uri(&1, SSL.ssl_enabled?(state)))
  end

  @spec keycloak_uri_for_realm(StateSummary.t(), String.t()) :: URI.t()
  def keycloak_uri_for_realm(state, realm) do
    state
    |> uri_for_battery(:keycloak)
    |> URI.append_path("/realms/#{realm}")
  end

  @spec keycloak_uris_for_realm(StateSummary.t(), String.t()) :: list(URI.t())
  def keycloak_uris_for_realm(state, realm) do
    state
    |> uris_for_battery(:keycloak)
    |> Enum.map(&URI.append_path(&1, "/realms/#{realm}"))
  end

  @spec keycloak_console_uri_for_realm(StateSummary.t(), String.t()) :: URI.t()
  def keycloak_console_uri_for_realm(state, realm) do
    state
    |> uri_for_battery(:keycloak)
    |> URI.append_path("/admin/#{realm}/console")
  end

  @spec keycloak_console_uris_for_realm(StateSummary.t(), String.t()) :: list(URI.t())
  def keycloak_console_uris_for_realm(state, realm) do
    state
    |> uris_for_battery(:keycloak)
    |> Enum.map(&URI.append_path(&1, "/admin/#{realm}/console"))
  end

  @spec project_dashboard(StateSummary.t()) :: URI.t()
  def project_dashboard(state) do
    state
    |> uri_for_battery(:grafana)
    |> URI.append_path("/d/projects/projects")
  end

  @spec project_dashboards(StateSummary.t()) :: list(URI.t())
  def project_dashboards(state) do
    state
    |> uris_for_battery(:grafana)
    |> Enum.map(&URI.append_path(&1, "/d/projects/projects"))
  end

  @spec cloud_native_pg_dashboard(StateSummary.t()) :: URI.t()
  def cloud_native_pg_dashboard(state) do
    state
    |> uri_for_battery(:grafana)
    |> URI.append_path("/d/cloudnative-pg/cloudnativepg")
  end

  @spec cloud_native_pg_dashboards(StateSummary.t()) :: list(URI.t())
  def cloud_native_pg_dashboards(state) do
    state
    |> uris_for_battery(:grafana)
    |> Enum.map(&URI.append_path(&1, "/d/cloudnative-pg/cloudnativepg"))
  end

  @spec pod_dashboard(StateSummary.t()) :: URI.t()
  def pod_dashboard(state) do
    state
    |> uri_for_battery(:grafana)
    |> URI.append_path("/d/k8s_views_pods/kubernetes-views-pods")
  end

  @spec pod_dashboards(StateSummary.t()) :: list(URI.t())
  def pod_dashboards(state) do
    state
    |> uris_for_battery(:grafana)
    |> Enum.map(&URI.append_path(&1, "/d/k8s_views_pods/kubernetes-views-pods"))
  end

  @spec knative_url(StateSummary.t(), Service.t()) :: URI.t()
  def knative_url(state, service) do
    state
    |> Hosts.knative_host(service)
    |> build_uri(SSL.ssl_enabled?(state))
  end

  @spec knative_urls(StateSummary.t(), Service.t()) :: list(URI.t())
  def knative_urls(state, service) do
    state
    |> Hosts.knative_hosts(service)
    |> Enum.map(&build_uri(&1, SSL.ssl_enabled?(state)))
  end

  @spec home_base_url(StateSummary.t()) :: URI.t()
  def home_base_url(state) do
    case_result =
      case Core.config_field(state, :usage) do
        :internal_dev ->
          "http://home.127-0-0-1.batrsinc.co:4100"

        _ ->
          "https://home.prod.batteriesincl.com/"
      end

    URI.new!(case_result)
  end

  @spec append_path_to_string(URI.t(), String.t()) :: String.t()
  def append_path_to_string(uri, path), do: uri |> URI.append_path(path) |> URI.to_string()

  defp build_uri(host, false = _ssl_enabled?), do: URI.new!("http://#{host}")
  defp build_uri(host, true = _ssl_enabled?), do: %URI{URI.new!("https://#{host}") | scheme: "https", port: 443}
end
