defmodule CommonCore.Resources.MetalLBMonitoring do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "metallb-monitoring"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:monitoring_pod_monitor_controller, battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("jobLabel", "app.kubernetes.io/name")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("podMetricsEndpoints", [%{"path" => "/metrics", "port" => "monitoring"}])
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => "metallb", "battery/component" => "controller"}}
      )

    :monitoring_pod_monitor
    |> B.build_resource()
    |> B.name("metallb-controller")
    |> B.component_labels("controller")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
    |> F.require(battery.config.enable_pod_monitor)
  end

  resource(:monitoring_pod_monitor_speaker, battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("jobLabel", "app.kubernetes.io/name")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("podMetricsEndpoints", [%{"path" => "/metrics", "port" => "monitoring"}])
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => "metallb", "battery/component" => "speaker"}}
      )

    :monitoring_pod_monitor
    |> B.build_resource()
    |> B.name("metallb-speaker")
    |> B.component_labels("speaker")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
    |> F.require(battery.config.enable_pod_monitor)
  end

  resource(:monitoring_service_monitor_controller, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"honorLabels" => true, "port" => "metrics"}])
      |> Map.put("jobLabel", "app.kubernetes.io/name")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"name" => "metallb-controller-monitor-service"}}
      )

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("metallb-controller-monitor")
    |> B.namespace(namespace)
    |> B.component_labels("speaker")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:monitoring_service_monitor_speaker, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{"honorLabels" => true, "port" => "metrics"},
        %{"honorLabels" => true, "port" => "frrmetrics"}
      ])
      |> Map.put("jobLabel", "app.kubernetes.io/name")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("selector", %{"matchLabels" => %{"name" => "metallb-speaker-monitor-service"}})

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("metallb-speaker-monitor")
    |> B.namespace(namespace)
    |> B.component_labels("speaker")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_controller_monitor, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("clusterIP", "None")
      |> Map.put("ports", [%{"name" => "metrics", "port" => 7472, "targetPort" => 7472}])
      |> Map.put("selector", %{"battery/app" => "metallb", "battery/component" => "controller"})
      |> Map.put("sessionAffinity", "None")

    :service
    |> B.build_resource()
    |> B.name("metallb-controller-monitor-service")
    |> B.namespace(namespace)
    |> B.label("name", "metallb-controller-monitor-service")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_speaker_monitor, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("clusterIP", "None")
      |> Map.put("ports", [
        %{"name" => "metrics", "port" => 7472, "targetPort" => 7472},
        %{"name" => "frrmetrics", "port" => 7473, "targetPort" => 7473}
      ])
      |> Map.put("selector", %{"battery/app" => "metallb", "battery/component" => "speaker"})
      |> Map.put("sessionAffinity", "None")

    :service
    |> B.build_resource()
    |> B.name("metallb-speaker-monitor-service")
    |> B.namespace(namespace)
    |> B.label("name", "metallb-speaker-monitor-service")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
