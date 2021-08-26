defmodule KubeResources.AlertManager do
  @moduledoc """
  Add on alert manager.
  """
  alias KubeResources.MonitoringSettings

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
          "battery/managed" => "True"
        }
      }
    }
  end

  def config(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "monitoring.coreos.com/v1alpha1",
      "kind" => "AlertmanagerConfig",
      "metadata" => %{
        "name" => "alertmanager",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "alertmanager",
          "battery/managed" => "True"
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
          "battery/managed" => "True"
        }
      },
      "spec" => %{
        "image" => "#{image}:#{version}",
        "nodeSelector" => %{
          "kubernetes.io/os": "linux"
        },
        # TODO: This doesn't work for alertmanger...
        #
        # "externalUrl" => "/x/alertmanager/",
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
          "battery/managed" => "True"
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
