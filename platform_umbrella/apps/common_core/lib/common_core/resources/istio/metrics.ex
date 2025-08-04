defmodule CommonCore.Resources.Istio.Metrics do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-metrics"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:pod_monitor_envoy_stats, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("jobLabel", "envoy-stats")
      |> Map.put("namespaceSelector", %{"any" => true})
      |> Map.put("podMetricsEndpoints", [
        %{
          "interval" => "15s",
          "path" => "/stats/prometheus",
          "port" => "http-envoy-prom",
          "relabelings" => [
            %{
              "action" => "keep",
              "regex" => "istio-proxy",
              "sourceLabels" => ["__meta_kubernetes_pod_container_name"]
            },
            %{
              "action" => "keep",
              "sourceLabels" => ["__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape"]
            },
            %{
              "action" => "replace",
              "regex" => "([^:]+)(?::\\d+)?;(\\d+)",
              "replacement" => "$1:$2",
              "sourceLabels" => [
                "__address__",
                "__meta_kubernetes_pod_annotation_prometheus_io_port"
              ],
              "targetLabel" => "__address__"
            },
            %{"action" => "labeldrop", "regex" => "__meta_kubernetes_pod_label_(.+)"},
            %{
              "action" => "replace",
              "sourceLabels" => ["__meta_kubernetes_namespace"],
              "targetLabel" => "namespace"
            },
            %{
              "action" => "replace",
              "sourceLabels" => ["__meta_kubernetes_pod_name"],
              "targetLabel" => "pod_name"
            }
          ]
        }
      ])
      |> Map.put(
        "selector",
        %{
          "matchExpressions" => [
            %{"key" => "istio-prometheus-ignore", "operator" => "DoesNotExist"},
            %{"key" => "service.istio.io/canonical-name", "operator" => "Exists"}
          ]
        }
      )

    :monitoring_pod_monitor
    |> B.build_resource()
    |> B.name("envoy-stats-monitor")
    |> B.namespace(namespace)
    |> B.label("monitoring", "istio-proxies")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_monitor_istio_component, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"interval" => "15s", "port" => "http-monitoring"}])
      |> Map.put("jobLabel", "istio")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put(
        "selector",
        %{"matchExpressions" => [%{"key" => "istio", "operator" => "In", "values" => ["pilot"]}]}
      )
      |> Map.put("targetLabels", ["app"])

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("istio-component-monitor")
    |> B.namespace(namespace)
    |> B.label("monitoring", "istio-components")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
