defmodule KubeResources.MonitoringKubeProxy do
  use KubeExt.IncludeResource,
    proxy_json: "priv/raw_files/prometheus_stack/proxy.json"

  use KubeExt.ResourceGenerator

  alias KubeResources.MonitoringSettings, as: Settings

  @app "monitoring_kube_proxy"

  resource(:service_kube_proxy) do
    B.build_resource(:service)
    |> B.name("battery-kube-proxy")
    |> B.namespace("kube-system")
    |> B.app_labels(@app)
    |> B.label("jobLabel", "kube-proxy")
    |> B.spec(%{
      "ports" => [
        %{"name" => "http-metrics", "port" => 10_249, "protocol" => "TCP", "targetPort" => 10_249}
      ],
      "selector" => %{"k8s-app" => "kube-proxy"}
    })
  end

  resource(:service_monitor, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_monitor)
    |> B.name("battery-kube-proxy")
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
        "matchLabels" => %{
          "battery/app" => @app
        }
      }
    })
  end

  resource(:prometheus_rule, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-proxy")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-system-kube-proxy",
          "rules" => [
            %{
              "alert" => "KubeProxyDown",
              "annotations" => %{
                "description" => "KubeProxy has disappeared from Prometheus target discovery.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeproxydown",
                "summary" => "Target disappeared from Prometheus target discovery."
              },
              "expr" => "absent(up{job=\"kube-proxy\"} == 1)",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            }
          ]
        }
      ]
    })
  end

  resource(:config_map_battery_kube_prometheus_st_proxy, config) do
    namespace = Settings.namespace(config)
    data = %{"proxy.json" => get_resource(:proxy_json)}

    B.build_resource(:config_map)
    |> B.name("battery-kube-proxy")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end
end
