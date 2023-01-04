defmodule CommonCore.SystemState.Hosts do
  import CommonCore.SystemState.Namespaces

  alias CommonCore.SystemState.StateSummary

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

  def knative_host(%StateSummary{} = state) do
    state |> ip() |> host("webapp", "user")
  end

  defp ip(state) do
    state |> ingress_ips() |> List.first()
  end

  defp host(ip, name, group \\ "core") do
    "#{name}.#{group}.#{ip}.ip.batteriesincl.com"
  end

  defp ingress_ips(%StateSummary{} = state) do
    istio_namespace = istio_namespace(state)
    ingress_name = "ingressgateway"

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
