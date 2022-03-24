defmodule KubeState.IstioIngress do
  def single_address do
    KubeState.services()
    |> ingress_ips_from_services()
    |> List.first() || "127.0.0.1"
  end

  def all_addresses do
    ingress_ips_from_services(KubeState.services())
  end

  defp ingress_ips_from_services(services) when services == [] do
    ["127.0.0.1"]
  end

  defp ingress_ips_from_services(nil = _services), do: ["127.0.0.1"]

  defp ingress_ips_from_services(services) when is_list(services) do
    matching =
      Enum.find(services, fn s ->
        K8s.Resource.name(s) == "istio-ingressgateway" and
          K8s.Resource.namespace(s) == "battery-ingress"
      end)

    case matching do
      nil ->
        ["127.0.0.1"]

      value ->
        value
        |> get_in(["status", "loadBalancer", "ingress"])
        |> Enum.filter(fn pos -> pos != nil end)
        |> Enum.map(fn pos -> Map.get(pos, "ip") end)
        |> Enum.sort(:desc)
    end
  end
end
