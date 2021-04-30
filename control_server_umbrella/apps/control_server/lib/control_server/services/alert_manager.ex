defmodule ControlServer.Services.AlertManager do
  @moduledoc """
  Add on alert manager.
  """
  alias ControlServer.Services.MonitoringSettings

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)
    name = MonitoringSettings.alertmanager_name(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      }
    }
  end

  def config(config) do
    namespace = MonitoringSettings.namespace(config)
    name = MonitoringSettings.alertmanager_name(config)

    %{
      "apiVersion" => "monitoring.coreos.com/v1alpha1",
      "kind" => "AlertmanagerConfig",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace,
        "labels" => %{
          "alertmanager" => name
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
    name = MonitoringSettings.alertmanager_name(config)
    image = MonitoringSettings.alertmanager_image(config)
    version = MonitoringSettings.alertmanager_version(config)

    %{
      "apiVersion" => "monitoring.coreos.com/v1",
      "kind" => "Alertmanager",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      },
      "spec" => %{
        "image" => "#{image}:#{version}",
        "nodeSelector" => %{
          "kubernetes.io/os": "linux"
        },
        "alertmanagerConfigSelector" => %{
          "matchLables" => %{"alertmanager" => name}
        },
        "replicas" => 1,
        "securityContext" => %{
          "fsGroup" => 2000,
          "runAsNonRoot" => true,
          "runAsUser" => 1000
        },
        "serviceAccountName" => name,
        "version" => version
      }
    }
  end

  def service(config) do
    namespace = MonitoringSettings.namespace(config)
    name = MonitoringSettings.alertmanager_name(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => "web",
            "port" => 9093,
            "targetPort" => "web"
          }
        ],
        "selector" => %{
          "alertmanager" => name
        },
        "sessionAffinity" => "ClientIP"
      }
    }
  end
end
