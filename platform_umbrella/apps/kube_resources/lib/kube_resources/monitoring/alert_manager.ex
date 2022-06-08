defmodule KubeResources.AlertManager do
  @moduledoc """
  Add on alert manager.
  """
  alias KubeExt.Builder, as: B
  alias KubeResources.IstioConfig.VirtualService
  alias KubeResources.MonitoringSettings
  alias KubeExt.KubeState.Hosts

  @app_name "alertmanager"

  @url_base "/x/alertmanager"

  def materialize(config) do
    %{
      "/account" => service_account(config),
      "/config" => alertmanager_config(config),
      "/alertmanager" => alertmanager(config),
      "/service" => service(config)
    }
  end

  def virtual_service(config) do
    namespace = MonitoringSettings.namespace(config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("alertmanager")
    |> B.spec(VirtualService.rewriting(@url_base, "alertmanager-main"))
  end

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: "/services/monitoring/alert_manager"

  def url, do: "//#{Hosts.control_host()}#{@url_base}"

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-alertmanager",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "alertmanager",
          "battery/managed" => "true"
        }
      }
    }
  end

  def alertmanager_config(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "monitoring.coreos.com/v1alpha1",
      "kind" => "AlertmanagerConfig",
      "metadata" => %{
        "name" => "alertmanager",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "alertmanager",
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "route" => %{
          "groupBy" => [
            "namespace"
          ],
          "groupWait" => "30s",
          "groupInterval" => "20m",
          "repeatInterval" => "12h",
          "routes" => [
            %{"match" => %{"alertname" => "Watchdog"}, "receiver" => "Watchdog"},
            %{"match" => %{"severity" => "critical"}, "receiver" => "Critical"}
          ]
        },
        "receivers" => [
          %{"name" => "Default"},
          %{"name" => "Watchdog"},
          %{"name" => "Critical"}
        ]
      }
    }
  end

  def alertmanager(config) do
    namespace = MonitoringSettings.namespace(config)
    image = MonitoringSettings.alertmanager_image(config)
    version = MonitoringSettings.alertmanager_version(config)

    %{
      "apiVersion" => "monitoring.coreos.com/v1",
      "kind" => "Alertmanager",
      "metadata" => %{
        "name" => "alertmanager",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "alertmanager",
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "image" => "#{image}:#{version}",
        "nodeSelector" => %{
          "kubernetes.io/os": "linux"
        },
        "alertmanagerConfigSelector" => %{
          "matchLables" => %{"alertmanager" => "alertmanager"}
        },
        "replicas" => 1,
        "securityContext" => %{
          "fsGroup" => 2000,
          "runAsNonRoot" => true,
          "runAsUser" => 1000
        },
        "serviceAccountName" => "battery-alertmanager",
        "version" => version
      }
    }
  end

  def service(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => "alertmanager-main",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "alertmanager",
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => "web",
            "port" => 80,
            "targetPort" => "web"
          }
        ],
        "selector" => %{
          "alertmanager" => "alertmanager"
        },
        "sessionAffinity" => "ClientIP"
      }
    }
  end
end
