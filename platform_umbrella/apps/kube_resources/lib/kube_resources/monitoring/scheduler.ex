defmodule KubeResources.MonitoringScheduler do
  use KubeExt.IncludeResource,
    scheduler_json: "priv/raw_files/prometheus_stack/scheduler.json"

  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "monitoring_scheduler"

  resource(:config_map, _battery, state) do
    namespace = core_namespace(state)
    data = %{"scheduler.json" => get_resource(:scheduler_json)}

    B.build_resource(:config_map)
    |> B.name("battery-kube-system-scheduler")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:prometheus_rule_rules, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-system-scheduler.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kube-scheduler.rules",
          "rules" => [
            %{
              "expr" =>
                "histogram_quantile(0.99, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.99"},
              "record" =>
                "cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.99, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.99"},
              "record" =>
                "cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.99, sum(rate(scheduler_binding_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.99"},
              "record" => "cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.9, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.9"},
              "record" =>
                "cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.9, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.9"},
              "record" =>
                "cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.9, sum(rate(scheduler_binding_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.9"},
              "record" => "cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.5, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.5"},
              "record" =>
                "cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.5, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.5"},
              "record" =>
                "cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.5, sum(rate(scheduler_binding_duration_seconds_bucket{job=\"kube-scheduler\"}[5m])) without(instance, pod))",
              "labels" => %{"quantile" => "0.5"},
              "record" => "cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile"
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-system-scheduler")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-system-scheduler",
          "rules" => [
            %{
              "alert" => "KubeSchedulerDown",
              "annotations" => %{
                "description" =>
                  "KubeScheduler has disappeared from Prometheus target discovery.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeschedulerdown",
                "summary" => "Target disappeared from Prometheus target discovery."
              },
              "expr" => "absent(up{job=\"kube-scheduler\"} == 1)",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            }
          ]
        }
      ]
    })
  end

  resource(:service) do
    B.build_resource(:service)
    |> B.name("battery-kube-scheduler")
    |> B.namespace("kube-system")
    |> B.app_labels(@app_name)
    |> B.label("jobLabel", "kube-scheduler")
    |> B.spec(%{
      "clusterIP" => "None",
      "ports" => [
        %{"name" => "http-metrics", "port" => 10_251, "protocol" => "TCP", "targetPort" => 10_251}
      ],
      "selector" => %{"component" => "kube-scheduler"},
      "type" => "ClusterIP"
    })
  end

  resource(:service_monitor, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_monitor)
    |> B.name("battery-kube-scheduler")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "endpoints" => [
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "port" => "http-metrics"
        }
      ],
      "jobLabel" => "jobLabel",
      "namespaceSelector" => %{"matchNames" => ["kube-system"]},
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app_name
        }
      }
    })
  end
end
