defmodule CommonCore.Resources.BatteryCore do
  @moduledoc false

  use CommonCore.Resources.ResourceGenerator, app_name: "battery-core"

  import CommonCore.Resources.StorageClass

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Batteries

  resource(:core_namespace, battery, state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.core_namespace)
    |> B.label("istio-injection", "disabled")
    |> B.label("istio.io/dataplane-mode", "ambient")
    |> maybe_add_waypoint_label(state)
  end

  resource(:base_namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.base_namespace)
    |> B.label("elbv2.k8s.aws/service-webhook", "disabled")
    |> B.label("istio-injection", "disabled")
    |> B.label("istio.io/dataplane-mode", "none")
  end

  resource(:data_namespace, battery, _state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.data_namespace)
    |> B.label("istio-injection", "disabled")
    |> B.label("istio.io/dataplane-mode", "ambient")
  end

  resource(:ai_namespace, battery, state) do
    :namespace
    |> B.build_resource()
    |> B.name(battery.config.ai_namespace)
    |> B.label("istio-injection", "disabled")
    |> B.label("istio.io/dataplane-mode", "ambient")
    |> maybe_add_waypoint_label(state)
  end

  multi_resource(:storage_class, battery) do
    if battery.config.cluster_type == :aws do
      generate_eks_storage_classes()
    else
      []
    end
  end

  defp maybe_add_waypoint_label(resource, state) do
    if Batteries.batteries_installed?(state, :keycloak),
      do: B.label(resource, "istio.io/use-waypoint", "waypoint"),
      else: resource
  end
end
