defmodule CommonCore.Resources.KnativeMetrics do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "knative-metrics"

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:monitoring_service_monitor_controller, battery, state) do
    spec =
      %{}
      |> Map.put("endpoints", [
        %{"honorLabels" => true, "interval" => "30s", "path" => "/metrics", "port" => "http-metrics"}
      ])
      |> Map.put("namespaceSelector", %{"matchNames" => [battery.config.namespace]})
      |> Map.put("selector", %{"matchLabels" => %{"battery/component" => "controller"}})

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("controller")
    |> B.namespace(battery.config.namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:monitoring_service_monitor_autoscaler, battery, state) do
    spec =
      %{}
      |> Map.put("endpoints", [
        %{"honorLabels" => true, "interval" => "30s", "path" => "/metrics", "port" => "http-metrics"}
      ])
      |> Map.put("namespaceSelector", %{"matchNames" => [battery.config.namespace]})
      |> Map.put("selector", %{"matchLabels" => %{"battery/component" => "autoscaler"}})

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("autoscaler")
    |> B.namespace(battery.config.namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:monitoring_service_monitor_activator, battery, state) do
    spec =
      %{}
      |> Map.put("endpoints", [
        %{"honorLabels" => true, "interval" => "30s", "path" => "/metrics", "port" => "http-metrics"}
      ])
      |> Map.put("namespaceSelector", %{"matchNames" => [battery.config.namespace]})
      |> Map.put("selector", %{"matchLabels" => %{"battery/component" => "activator"}})

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("activator")
    |> B.namespace(battery.config.namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:monitoring_service_monitor_webhook, battery, state) do
    spec =
      %{}
      |> Map.put("endpoints", [
        %{"honorLabels" => true, "interval" => "30s", "path" => "/metrics", "port" => "http-metrics"}
      ])
      |> Map.put("namespaceSelector", %{"matchNames" => [battery.config.namespace]})
      |> Map.put("selector", %{"matchLabels" => %{"battery/component" => "webhook"}})

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("webhook")
    |> B.namespace(battery.config.namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
