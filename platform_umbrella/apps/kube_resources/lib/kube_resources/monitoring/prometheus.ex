defmodule KubeResources.Prometheus do
  use KubeExt.IncludeResource,
    run_sh: "priv/raw_files/prometheus_stack/run.sh"

  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeExt.KubeState.Hosts
  alias KubeResources.IstioConfig.VirtualService

  @app_name "prometheus"
  @url_base "/x/prometheus"

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: "/services/monitoring/prometheus"

  def url, do: "http://#{Hosts.control_host()}#{@url_base}"

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("prometheus")
    |> B.spec(VirtualService.rewriting("/x/prometheus", "battery-prometheus-prometheus"))
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:cluster_role_battery_kube_prometheus_prometheus) do
    B.build_resource(:cluster_role)
    |> B.name("battery-prometheus-prometheus")
    |> B.app_labels(@app_name)
    |> B.rules([
      %{
        "apiGroups" => [""],
        "resources" => ["nodes", "nodes/metrics", "services", "endpoints", "pods"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"nonResourceURLs" => ["/metrics", "/metrics/cadvisor"], "verbs" => ["get"]}
    ])
  end

  resource(:cluster_role_binding_battery_kube_prometheus_prometheus, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-prometheus-prometheus")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref("battery-prometheus-prometheus"))
    |> B.subject(B.build_service_account("battery-prometheus-prometheus", namespace))
  end

  resource(:prometheus_battery_kube_st, battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:prometheus)
    |> B.name("battery-prometheus-prometheus")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "alerting" => %{
        "alertmanagers" => [
          %{
            "apiVersion" => "v2",
            "name" => "battery-prometheus-alertmanager",
            "namespace" => namespace,
            "pathPrefix" => "/",
            "port" => "http-web"
          }
        ]
      },
      "enableAdminAPI" => false,
      "externalUrl" => @url_base,
      "image" => battery.config.image,
      "listenLocal" => false,
      "logFormat" => "json",
      "logLevel" => "debug",
      "paused" => false,
      "podMonitorNamespaceSelector" => %{},
      "podMonitorSelector" => %{},
      "portName" => "http-web",
      "probeNamespaceSelector" => %{},
      "probeSelector" => %{},
      "replicas" => 1,
      "retention" => battery.config.retention,
      "routePrefix" => "/",
      "ruleNamespaceSelector" => %{},
      "ruleSelector" => %{},
      "securityContext" => %{
        "fsGroup" => 2000,
        "runAsGroup" => 2000,
        "runAsNonRoot" => true,
        "runAsUser" => 1000
      },
      "serviceAccountName" => "battery-prometheus-prometheus",
      "serviceMonitorNamespaceSelector" => %{},
      "serviceMonitorSelector" => %{},
      "shards" => 1,
      "version" => battery.config.version,
      "walCompression" => true
    })
  end

  resource(:service_account_prometheus, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("battery-prometheus-prometheus")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_prometheus, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service)
    |> B.name("battery-prometheus-prometheus")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("self-monitor", "true")
    |> B.spec(%{
      "ports" => [%{"name" => "http-web", "port" => 9090, "targetPort" => 9090}],
      "publishNotReadyAddresses" => false,
      "selector" => %{
        "prometheus" => "battery-prometheus-prometheus"
      }
    })
  end

  resource(:service_monitor_prometheus, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_monitor)
    |> B.name("battery-prometheus-prometheus")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "endpoints" => [%{"path" => "/metrics", "port" => "http-web"}],
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app_name, "self-monitor" => "true"}
      }
    })
  end
end
