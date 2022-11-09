defmodule KubeResources.MonitoringControllerManager do
  use KubeExt.IncludeResource,
    controller_manager_json: "priv/raw_files/prometheus_stack/controller-manager.json"

  use KubeExt.ResourceGenerator
  alias KubeResources.MonitoringSettings, as: Settings

  @app "monitoring_controller_manager"

  resource(:config_map, battery, _state) do
    namespace = Settings.namespace(battery.config)
    data = %{"controller-manager.json" => get_resource(:controller_manager_json)}

    B.build_resource(:config_map)
    |> B.name("battery-controller-manager")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:prometheus_rule, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-prometheus-st-kubernetes-system-controller-manager")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-system-controller-manager",
          "rules" => [
            %{
              "alert" => "KubeControllerManagerDown",
              "annotations" => %{
                "description" =>
                  "KubeControllerManager has disappeared from Prometheus target discovery.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubecontrollermanagerdown",
                "summary" => "Target disappeared from Prometheus target discovery."
              },
              "expr" => "absent(up{job=\"kube-controller-manager\"} == 1)",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            }
          ]
        }
      ]
    })
  end

  resource(:service_monitor, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_monitor)
    |> B.name("battery-kube-prometheus-st-kube-controller-manager")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
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
        "matchLabels" => %{"app" => @app}
      }
    })
  end

  resource(:service) do
    B.build_resource(:service)
    |> B.name("battery-controller-manager")
    |> B.namespace("kube-system")
    |> B.app_labels(@app)
    |> B.label("jobLabel", "kube-controller-manager")
    |> B.spec(%{
      "ports" => [
        %{"name" => "http-metrics", "port" => 10_252, "protocol" => "TCP", "targetPort" => 10_252}
      ],
      "selector" => %{"component" => "kube-controller-manager"}
    })
  end
end
