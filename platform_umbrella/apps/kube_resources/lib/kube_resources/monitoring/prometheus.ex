defmodule KubeResources.Prometheus do
  @moduledoc """
  This module contains all the code to interact with, including starting, prometheuses.

  Currently this is around config generation via Monitoring.materialize/1
  and Ingress generation via KubResources.Ingress
  """

  alias KubeExt.Builder, as: B
  alias KubeResources.IstioConfig.VirtualService
  alias KubeResources.MonitoringSettings
  alias ControlServer.Services.RunnableService

  @port 8080
  @port_name "http"

  @app_name "prometheus"

  def materialize(config) do
    %{
      "/account" => service_account(config),
      "/cluster_role" => cluster_role(config),
      "/cluster_role_bind" => cluster_role_binding(config),
      "/prometheus_main" => prometheus(config),
      "/service" => service(config)
    }
  end

  def ingress(config) do
    namespace = MonitoringSettings.namespace(config)

    B.build_resource(:ingress, "/x/prometheus", "prometheus-main", "http")
    |> B.rewriting_ingress()
    |> B.name("prometheus")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def virtual_service(config) do
    namespace = MonitoringSettings.namespace(config)

    B.build_resource(:virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("prometheus")
    |> B.spec(VirtualService.rewriting("/x/prometheus", "prometheus-main"))
  end

  def prometheus(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "monitoring.coreos.com/v1",
      "kind" => "Prometheus",
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "True"
        },
        "name" => "prometheus",
        "namespace" => namespace
      },
      "spec" => prometheus_spec(config)
    }
  end

  def prometheus_spec(config) do
    image = MonitoringSettings.prometheus_image(config)
    version = MonitoringSettings.prometheus_version(config)

    %{
      "image" => "#{image}:#{version}",
      "logLevel" => "debug",
      "externalUrl" => "/x/prometheus",
      "serviceAccountName" => "battery-prometheus",
      "version" => version
    }
    |> Map.merge(selectors(config))
    |> Map.merge(limits(config))
    |> Map.merge(alerting(config))
  end

  defp alerting(config), do: alerting(config, RunnableService.active?(:alert_manager))

  defp alerting(config, true = _is_active) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "alerting" => %{
        "alertmanagers" => [
          %{
            "apiVersion" => "v2",
            "name" => "alertmanager-main",
            "namespace" => namespace,
            "port" => "main"
          }
        ]
      }
    }
  end

  defp alerting(_config, _is_active), do: %{}

  defp selectors(_config) do
    %{
      # select everything.
      "podMonitorNamespaceSelector" => %{},
      "podMonitorSelector" => %{},
      "probeNamespaceSelector" => %{},
      "probeSelector" => %{},
      "serviceMonitorNamespaceSelector" => %{},
      "serviceMonitorSelector" => %{},
      "nodeSelector" => %{
        "kubernetes.io/os": "linux"
      }
    }
  end

  def limits(config) do
    memory = MonitoringSettings.prometheus_memory(config)
    replicas = MonitoringSettings.prometheus_replicas(config)

    %{
      "replicas" => replicas,
      "resources" => %{
        "requests" => %{
          "memory" => memory
        }
      },
      "securityContext" => %{
        "fsGroup" => 2000,
        "runAsNonRoot" => true,
        "runAsUser" => 1000
      }
    }
  end

  def service(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus",
          "battery/managed" => "True"
        },
        "name" => "prometheus-main",
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => @port_name,
            "port" => @port,
            # this is the name that prometheus-operator uses.
            "targetPort" => "web"
          }
        ],
        "selector" => %{
          "prometheus" => "prometheus"
        },
        "sessionAffinity" => "ClientIP"
      }
    }
  end

  def monitors(config) do
    namespace = MonitoringSettings.namespace(config)

    [
      %{
        "apiVersion" => "monitoring.coreos.com/v1",
        "kind" => "ServiceMonitor",
        "metadata" => %{
          "labels" => %{
            "battery/app" => "prometheus",
            "battery/managed" => "True"
          },
          "name" => "prometheus",
          "namespace" => namespace
        },
        "spec" => %{
          "endpoints" => [%{"interval" => "15s", "port" => @port_name}],
          "selector" => %{"matchLabels" => %{"battery/app" => "prometheus"}}
        }
      }
    ]
  end

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("battery-prometheus")
    |> B.app_labels(@app_name)
    |> B.namespace(namespace)
  end

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus",
          "battery/managed" => "True"
        },
        "name" => "battery-prometheus"
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["nodes/metrics"],
          "verbs" => ["get"]
        },
        %{
          "nonResourceURLs" => ["/metrics"],
          "verbs" => ["get"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["services", "endpoints", "pods"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["extensions"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "verbs" => ["get"]
        }
      ]
    }
  end

  def cluster_role_binding(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus",
          "battery/managed" => "True"
        },
        "name" => "battery-prometheus"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-prometheus"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-prometheus",
          "namespace" => namespace
        }
      ]
    }
  end
end
