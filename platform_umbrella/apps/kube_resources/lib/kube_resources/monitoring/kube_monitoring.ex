defmodule KubeResources.KubeMonitoring do
  use KubeResources.ResourceGenerator, app_name: "kube-mon"

  import CommonCore.StateSummary.Namespaces

  alias KubeResources.Builder, as: B

  resource(:monitoring_node_monitor_cadvisor, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("bearerTokenFile", "/var/run/secrets/kubernetes.io/serviceaccount/token")
      |> Map.put("honorLabels", true)
      |> Map.put("interval", "30s")
      |> Map.put("metricRelabelConfigs", [
        %{"action" => "labeldrop", "regex" => "(uid)"},
        %{"action" => "labeldrop", "regex" => "(id|name)"},
        %{
          "action" => "drop",
          "regex" =>
            "(rest_client_request_duration_seconds_bucket|rest_client_request_duration_seconds_sum|rest_client_request_duration_seconds_count)",
          "source_labels" => ["__name__"]
        }
      ])
      |> Map.put("path", "/metrics/cadvisor")
      |> Map.put("relabelConfigs", [
        %{"action" => "labelmap", "regex" => "__meta_kubernetes_node_label_(.+)"},
        %{"sourceLabels" => ["__metrics_path__"], "targetLabel" => "metrics_path"},
        %{"replacement" => "kubelet", "targetLabel" => "job"}
      ])
      |> Map.put("scheme", "https")
      |> Map.put("scrapeTimeout", "5s")
      |> Map.put(
        "tlsConfig",
        %{
          "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
          "insecureSkipVerify" => true
        }
      )

    B.build_resource(:monitoring_node_monitor)
    |> B.name("battery-metrics-cadvisor")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:monitoring_node_monitor_kubelet, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("bearerTokenFile", "/var/run/secrets/kubernetes.io/serviceaccount/token")
      |> Map.put("honorLabels", true)
      |> Map.put("interval", "30s")
      |> Map.put("metricRelabelConfigs", [
        %{"action" => "labeldrop", "regex" => "(uid)"},
        %{"action" => "labeldrop", "regex" => "(id|name)"},
        %{
          "action" => "drop",
          "regex" =>
            "(rest_client_request_duration_seconds_bucket|rest_client_request_duration_seconds_sum|rest_client_request_duration_seconds_count)",
          "source_labels" => ["__name__"]
        }
      ])
      |> Map.put("relabelConfigs", [
        %{"action" => "labelmap", "regex" => "__meta_kubernetes_node_label_(.+)"},
        %{"sourceLabels" => ["__metrics_path__"], "targetLabel" => "metrics_path"},
        %{"replacement" => "kubelet", "targetLabel" => "job"}
      ])
      |> Map.put("scheme", "https")
      |> Map.put("scrapeTimeout", "5s")
      |> Map.put(
        "tlsConfig",
        %{
          "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
          "insecureSkipVerify" => true
        }
      )

    B.build_resource(:monitoring_node_monitor)
    |> B.name("battery-metrics-kubelet")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:monitoring_node_probes, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("bearerTokenFile", "/var/run/secrets/kubernetes.io/serviceaccount/token")
      |> Map.put("honorLabels", true)
      |> Map.put("interval", "30s")
      |> Map.put("metricRelabelConfigs", [
        %{"action" => "labeldrop", "regex" => "(uid)"},
        %{"action" => "labeldrop", "regex" => "(id|name)"},
        %{
          "action" => "drop",
          "regex" =>
            "(rest_client_request_duration_seconds_bucket|rest_client_request_duration_seconds_sum|rest_client_request_duration_seconds_count)",
          "source_labels" => ["__name__"]
        }
      ])
      |> Map.put("path", "/metrics/probes")
      |> Map.put("relabelConfigs", [
        %{"action" => "labelmap", "regex" => "__meta_kubernetes_node_label_(.+)"},
        %{"sourceLabels" => ["__metrics_path__"], "targetLabel" => "metrics_path"},
        %{"replacement" => "kubelet", "targetLabel" => "job"}
      ])
      |> Map.put("scheme", "https")
      |> Map.put("scrapeTimeout", "5s")
      |> Map.put(
        "tlsConfig",
        %{
          "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
          "insecureSkipVerify" => true
        }
      )

    B.build_resource(:monitoring_node_monitor)
    |> B.name("battery-metrics-probes")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_apiserver, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "port" => "https",
          "scheme" => "https",
          "tlsConfig" => %{
            "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
            "serverName" => "kubernetes"
          }
        }
      ])
      |> Map.put("jobLabel", "component")
      |> Map.put("namespaceSelector", %{"matchNames" => ["default"]})
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"component" => "apiserver", "provider" => "kubernetes"}}
      )

    B.build_resource(:monitoring_service_monitor)
    |> B.name("battery-metrics-apiserver")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_coredns, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "port" => "http-metrics"
        }
      ])
      |> Map.put("namespaceSelector", %{"matchNames" => ["kube-system"]})
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "coredns"}
      })

    B.build_resource(:monitoring_service_monitor)
    |> B.name("battery-metrics-coredns")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_victoria_metrics_k8s_stack_coredns) do
    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 9153, "protocol" => "TCP", "targetPort" => 9153}
      ])
      |> Map.put("selector", %{"k8s-app" => "kube-dns"})

    B.build_resource(:service)
    |> B.name("battery-metrics-coredns")
    |> B.namespace("kube-system")
    |> B.component_label("coredns")
    |> B.label("jobLabel", "coredns")
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_etcd, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "port" => "http-metrics",
          "scheme" => "https",
          "tlsConfig" => %{"caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"}
        }
      ])
      |> Map.put("jobLabel", "jobLabel")
      |> Map.put("namespaceSelector", %{"matchNames" => ["kube-system"]})
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "etcd"}
      })

    B.build_resource(:monitoring_service_monitor)
    |> B.name("battery-metrics-kube-etcd")
    |> B.namespace(namespace)
    |> B.component_label("etcd")
    |> B.spec(spec)
  end

  resource(:service_etcd) do
    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 2379, "protocol" => "TCP", "targetPort" => 2379}
      ])
      |> Map.put("selector", %{"component" => "etcd"})

    B.build_resource(:service)
    |> B.name("battery-metrics-kube-etcd")
    |> B.namespace("kube-system")
    |> B.component_label("etcd")
    |> B.label("jobLabel", "kube-etcd")
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_kube_controller_mananager, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "port" => "http-metrics",
          "scheme" => "https",
          "tlsConfig" => %{
            "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
            "serverName" => "kubernetes"
          }
        }
      ])
      |> Map.put("jobLabel", "jobLabel")
      |> Map.put("namespaceSelector", %{"matchNames" => ["kube-system"]})
      |> Map.put("selector", %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "battery/component" => "kube-controller-man"
        }
      })

    B.build_resource(:monitoring_service_monitor)
    |> B.name("battery-metrics-kube-controller-man")
    |> B.namespace(namespace)
    |> B.component_label("kube-controller-man")
    |> B.spec(spec)
  end

  resource(:service_kube_controller_man) do
    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 10_257, "protocol" => "TCP", "targetPort" => 10_257}
      ])
      |> Map.put("selector", %{"component" => "kube-controller-manager"})

    B.build_resource(:service)
    |> B.name("battery-metrics-kube-controller-man")
    |> B.namespace("kube-system")
    |> B.component_label("kube-controller-man")
    |> B.label("jobLabel", "kube-controller-manager")
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_kube_scheduler, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "port" => "http-metrics",
          "scheme" => "https",
          "tlsConfig" => %{"caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"}
        }
      ])
      |> Map.put("jobLabel", "jobLabel")
      |> Map.put("namespaceSelector", %{"matchNames" => ["kube-system"]})
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "kube-scheduler"}
      })

    B.build_resource(:monitoring_service_monitor)
    |> B.name("battery-metrics-kube-scheduler")
    |> B.namespace(namespace)
    |> B.component_label("kube-scheduler")
    |> B.spec(spec)
  end

  resource(:service_kube_scheduler) do
    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http-metrics", "port" => 10_251, "protocol" => "TCP", "targetPort" => 10_251}
      ])
      |> Map.put("selector", %{"component" => "kube-scheduler"})

    B.build_resource(:service)
    |> B.name("battery-metrics-kube-scheduler")
    |> B.namespace("kube-system")
    |> B.component_label("kube-scheduler")
    |> B.label("jobLabel", "kube-scheduler")
    |> B.spec(spec)
  end
end
