defmodule KubeExt.SystemState.Hosts do
  import KubeExt.SystemState.Namespaces

  alias KubeExt.SystemState.StateSummary

  @default ["127.0.0.1"]

  def control_host(%StateSummary{} = state) do
    state |> ingress_ips() |> List.first() |> host("control")
  end

  def gitea_host(%StateSummary{} = state) do
    state |> ingress_ips() |> List.last() |> host("gitea")
  end

  def harbor_host(%StateSummary{} = state) do
    state |> ingress_ips() |> List.first() |> host("harbor")
  end

  def knative_host(%StateSummary{} = state) do
    state |> ingress_ips() |> List.first() |> host("webapp")
  end

  defp host(ip, name) do
    "#{name}.#{ip}.ip.batteriesincl.com"
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
