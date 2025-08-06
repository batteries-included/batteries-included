defmodule CommonCore.Resources.Istio.Gateways do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-gateways"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary.Batteries

  # styler:sort
  @waypoint_enabled_batteries ~w(
    knative
    traditional_services
  )a

  resource(:ai_waypoint, _battery, state) do
    state |> ai_namespace() |> gateway_for_namespace(state)
  end

  resource(:core_waypoint, _battery, state) do
    state |> core_namespace() |> gateway_for_namespace(state)
  end

  multi_resource(:battery_waypoints, _battery, state) do
    @waypoint_enabled_batteries
    |> Enum.filter(&Batteries.batteries_installed?(state, &1))
    |> Enum.map(&(state |> battery_namespace(&1) |> gateway_for_namespace(state)))
  end

  defp gateway_for_namespace(ns, state) do
    :gateway
    |> B.build_resource()
    |> B.name("waypoint")
    |> B.namespace(ns)
    |> B.label("istio.io/waypoint-for", "all")
    |> B.spec(%{
      "gatewayClassName" => "istio-waypoint",
      "listeners" => [%{"name" => "mesh", "port" => 15_008, "protocol" => "HBONE"}]
    })
    |> F.require_battery(state, :sso)
  end
end
