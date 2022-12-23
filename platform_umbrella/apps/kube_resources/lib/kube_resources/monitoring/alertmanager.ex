defmodule KubeResources.Alertmanager do
  use KubeExt.IncludeResource,
    alertmanager_yaml: "priv/raw_files/prometheus_stack/alertmanager.yaml"

  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces
  import KubeExt.SystemState.Hosts

  alias KubeExt.SystemState.StateSummary
  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeExt.KubeState.Hosts
  alias KubeExt.Secret

  alias KubeResources.IstioConfig.VirtualService

  @app_name "alertmanager"
  @url_base "/x/alertmanager"

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: "/services/monitoring/alertmanager"

  def url, do: "http://#{Hosts.control_host()}#{@url_base}"

  def url(%StateSummary{} = state) do
    control = control_host(state)
    "http://#{control}#{@url_base}"
  end

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("alertmanager")
    |> B.spec(VirtualService.rewriting(@url_base, "battery-prometheus-alertmanager"))
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:alertmanager, battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:alertmanager)
    |> B.name("battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "alertmanagerConfigNamespaceSelector" => %{},
      "alertmanagerConfigSelector" => %{},
      "externalUrl" => url(state),
      "image" => battery.config.image,
      "listenLocal" => false,
      "logFormat" => "json",
      "logLevel" => "info",
      "paused" => false,
      "portName" => "http-web",
      "replicas" => 1,
      "retention" => "120h",
      "routePrefix" => "/",
      "securityContext" => %{
        "fsGroup" => 2000,
        "runAsGroup" => 2000,
        "runAsNonRoot" => true,
        "runAsUser" => 1000
      },
      "serviceAccountName" => "battery-prometheus-alertmanager",
      "version" => battery.config.version
    })
  end

  resource(:secret_alertmanager_alertmanager, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{} |> Map.put("alertmanager.yaml", get_resource(:alertmanager_yaml)) |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("alertmanager-battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  resource(:service_account_alertmanager, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_alertmanager, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service)
    |> B.name("battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("self-monitor", "true")
    |> B.spec(%{
      "ports" => [
        %{"name" => "http-web", "port" => 9093, "protocol" => "TCP", "targetPort" => 9093}
      ],
      "selector" => %{
        "alertmanager" => "battery-prometheus-alertmanager"
      },
      "type" => "ClusterIP"
    })
  end

  resource(:service_monitor_alertmanager, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_monitor)
    |> B.name("battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "endpoints" => [%{"path" => "/metrics", "port" => "http-web"}],
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "self-monitor" => "true"
        }
      }
    })
  end
end
