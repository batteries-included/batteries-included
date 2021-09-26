defmodule KubeResources.Prometheus do
  @moduledoc """
  This module contains all the code to interact with, including starting, prometheuses.

  Currently this is around config generation via Monitoring.materialize/1
  and Ingress generation via KubResources.Ingress
  """

  alias KubeExt.Builder, as: B
  alias KubeResources.IstioConfig.VirtualService
  alias KubeResources.MonitoringSettings

  @port 80
  @port_name "http"

  @app_name "prometheus"

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
    |> B.spec(VirtualService.rewriting("/x/prometheus", "prometheus"))
  end

  def prometheus(config) do
    namespace = MonitoringSettings.namespace(config)

    image = MonitoringSettings.prometheus_image(config)
    version = MonitoringSettings.prometheus_version(config)

    memory = MonitoringSettings.prometheus_memory(config)
    replicas = MonitoringSettings.prometheus_replicas(config)

    %{
      "apiVersion" => "monitoring.coreos.com/v1",
      "kind" => "Prometheus",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus",
          "battery/managed" => "True"
        },
        "name" => "prometheus",
        "namespace" => namespace
      },
      "spec" => %{
        # "alerting" => %{
        #   "alertmanagers" => [
        #     %{
        #       "name" => "alertmanager",
        #       "namespace" => namespace,
        #       "port" => "web"
        #     }
        #   ]
        # },
        "image" => "#{image}:#{version}",
        "nodeSelector" => %{
          "kubernetes.io/os": "linux"
        },
        "externalUrl" => "/x/prometheus",
        # select everything.
        "podMonitorNamespaceSelector" => %{},
        "podMonitorSelector" => %{},
        "probeNamespaceSelector" => %{},
        "probeSelector" => %{},
        "replicas" => replicas,
        "resources" => %{
          "requests" => %{
            "memory" => memory
          }
        },
        # "ruleSelector" => %{
        #   "matchLabels" => %{
        #     "prometheus" => "prometheus",
        #     "role" => "alert-rules"
        #   }
        # },
        "securityContext" => %{
          "fsGroup" => 2000,
          "runAsNonRoot" => true,
          "runAsUser" => 1000
        },
        "serviceAccountName" => "battery-prometheus",
        "serviceMonitorNamespaceSelector" => %{},
        "serviceMonitorSelector" => %{},
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

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-prometheus",
        "namespace" => namespace
      }
    }
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

  def config_role(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus",
          "battery/managed" => "True"
        },
        "name" => "prometheus-config",
        "namespace" => namespace
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "verbs" => ["get"]
        }
      ]
    }
  end

  def config_role_binding(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus",
          "battery/managed" => "True"
        },
        "name" => "prometheus",
        "namespace" => namespace
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "prometheus"
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

  def main_roles(config) do
    config
    |> MonitoringSettings.monitored_namespaces()
    |> Enum.map(fn mon_namespace ->
      %{
        "apiVersion" => "rbac.authorization.k8s.io/v1",
        "kind" => "Role",
        "metadata" => %{
          "labels" => %{
            "battery/app" => "prometheus",
            "battery/managed" => "True"
          },
          "name" => "battery-prometheus",
          "namespace" => mon_namespace
        },
        "rules" => [
          %{
            "apiGroups" => [""],
            "resources" => ["services", "endpoints", "pods"],
            "verbs" => ["get", "list", "watch"]
          },
          %{
            "apiGroups" => ["extensions"],
            "resources" => ["ingresses"],
            "verbs" => ["get", "list", "watch"]
          }
        ]
      }
    end)
  end

  def main_role_bindings(config) do
    namespace = MonitoringSettings.namespace(config)

    config
    |> MonitoringSettings.monitored_namespaces()
    |> Enum.map(fn mon_namespace ->
      %{
        "apiVersion" => "rbac.authorization.k8s.io/v1",
        "kind" => "RoleBinding",
        "metadata" => %{
          "labels" => %{
            "battery/app" => "prometheus",
            "battery/managed" => "True"
          },
          "name" => "battery-prometheus",
          "namespace" => mon_namespace
        },
        "roleRef" => %{
          "apiGroup" => "rbac.authorization.k8s.io",
          "kind" => "Role",
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
    end)
  end
end
