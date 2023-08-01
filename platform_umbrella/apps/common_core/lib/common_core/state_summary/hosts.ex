defmodule CommonCore.StateSummary.Hosts do
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.StateSummary

  @default ["127.0.0.1"]

  def control_host(%StateSummary{} = state) do
    state |> ip() |> host("control")
  end

  def gitea_host(%StateSummary{} = state) do
    state |> ip() |> host("gitea")
  end

  def grafana_host(%StateSummary{} = state) do
    state |> ip() |> host("grafana")
  end

  def vmselect_host(%StateSummary{} = state) do
    state |> ip() |> host("vmselect")
  end

  def vmagent_host(%StateSummary{} = state) do
    state |> ip() |> host("vmagent")
  end

  def harbor_host(%StateSummary{} = state) do
    state |> ip() |> host("harbor")
  end

  def smtp4dev_host(%StateSummary{} = state) do
    state |> ip() |> host("smtp4dev")
  end

  def keycloak_host(%StateSummary{} = state) do
    state |> ip() |> host("keycloak")
  end

  def keycloak_admin_host(%StateSummary{} = state) do
    state |> ip() |> host("keycloak-admin")
  end

  def kiali_host(%StateSummary{} = state) do
    state |> ip() |> host("kiali")
  end

  def knative_base_host(%StateSummary{} = state) do
    state |> ip() |> host("webapp", "user")
  end

  def knative_host(%StateSummary{} = state, service) do
    namespace = knative_namespace(state)
    "#{service.name}.#{namespace}.#{knative_base_host(state)}"
  end

  def notebooks_host(%StateSummary{} = state) do
    state |> ip() |> host("notebooks", "user")
  end

  defp ip(state) do
    state |> ingress_ips() |> List.first()
  end

  defp host(ip, name, group \\ "core") do
    "#{name}.#{group}.#{ip}.ip.batteriesincl.com"
  end

  defp ingress_ips(%StateSummary{} = state) do
    istio_namespace = istio_namespace(state)
    # the name of the ingress service.
    # We aren't using the Gateway name or the istio tag here
    # We are using metadata.name for service selection
    ingress_name = "istio-ingress"

    state.kube_state
    |> Map.get(:service, [])
    |> ingress_ips_from_service(istio_namespace, ingress_name)
    |> Enum.sort(:asc)
  end

  defp ingress_ips_from_service(services, istio_namespace, ingress_name) do
    Enum.find_value(services, @default, fn
      %{
        "metadata" => %{"name" => ^ingress_name, "namespace" => ^istio_namespace},
        "status" => %{"loadBalancer" => %{"ingress" => values}}
      } ->
        values
        |> Enum.filter(fn pos -> pos != nil end)
        |> Enum.map(fn pos -> Map.get(pos, "ip") end)

      _ ->
        nil
    end)
  end
end
