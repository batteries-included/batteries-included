defmodule KubeResources.MonitoringCoredns do
  use KubeExt.IncludeResource,
    k8s_coredns_json: "priv/raw_files/prometheus_stack/k8s-coredns.json"

  use KubeExt.ResourceGenerator
  alias KubeResources.MonitoringSettings, as: Settings

  @app "monitoring_coredns"

  resource(:service_monitor, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_monitor)
    |> B.name("battery-coredns")
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
      "selector" => %{"matchLabels" => %{"app" => @app}}
    })
  end

  resource(:config_map, battery, _state) do
    namespace = Settings.namespace(battery.config)
    data = %{"k8s-coredns.json" => get_resource(:k8s_coredns_json)}

    B.build_resource(:config_map)
    |> B.name("battery-coredns")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:service) do
    B.build_resource(:service)
    |> B.name("battery-coredns")
    |> B.namespace("kube-system")
    |> B.app_labels(@app)
    |> B.label("jobLabel", "coredns")
    |> B.spec(%{
      "clusterIP" => "None",
      "ports" => [
        %{"name" => "http-metrics", "port" => 9153, "protocol" => "TCP", "targetPort" => 9153}
      ],
      "selector" => %{"k8s-app" => "kube-dns"}
    })
  end
end
