defmodule KubeExt.KubeState.IstioIngress do
  import K8s.Resource.FieldAccessors

  @default "172.30.0.4"

  def single_address do
    get_services()
    |> ingress_ips_from_services()
    |> List.first() || @default
  end

  def all_addresses do
    ingress_ips_from_services(get_services())
  end

  defp ingress_ips_from_services(services) when services == [] do
    [@default]
  end

  defp ingress_ips_from_services(services) when is_list(services) do
    matching =
      Enum.find(services, fn s ->
        name(s) == "ingressgateway" and
          namespace(s) == "battery-istio"
      end)

    case matching do
      %{"status" => %{"loadBalancer" => %{"ingress" => value}}} ->
        value
        |> Enum.filter(fn pos -> pos != nil end)
        |> Enum.map(fn pos -> Map.get(pos, "ip") end)
        |> Enum.sort(:asc)

      _ ->
        [@default]
    end
  end

  defp get_services, do: KubeExt.KubeState.services()
end
