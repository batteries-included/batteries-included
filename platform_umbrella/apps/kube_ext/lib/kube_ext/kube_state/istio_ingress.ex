defmodule KubeExt.KubeState.IstioIngress do
  @default "172.30.0.4"

  def single_address do
    List.first(ingress_ips()) || @default
  end

  def all_addresses do
    ingress_ips()
  end

  defp ingress_ips do
    case KubeExt.KubeState.get(:service, "battery-istio", "ingressgateway") do
      {:ok, %{"status" => %{"loadBalancer" => %{"ingress" => value}}}} ->
        value
        |> Enum.filter(fn pos -> pos != nil end)
        |> Enum.map(fn pos -> Map.get(pos, "ip") end)
        |> Enum.sort(:asc)

      _ ->
        [@default]
    end
  end
end
