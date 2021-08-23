defmodule KubeResources.Prometheus do
  @moduledoc """
  This module contains all the code to interact with, including starting, prometheuses.any()

  Currently this is around config generation via Monitoring.materialize/1
  """

  alias KubeResources.MonitoringSettings

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
        "alerting" => %{
          "alertmanagers" => [
            %{
              "name" => "alertmanager",
              "namespace" => namespace,
              "port" => "web"
            }
          ]
        },
        "image" => "#{image}:#{version}",
        "nodeSelector" => %{
          "kubernetes.io/os": "linux"
        },

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
        "ruleSelector" => %{
          "matchLabels" => %{
            "prometheus" => "prometheus",
            "role" => "alert-rules"
          }
        },
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
        "name" => "prometheus",
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => "web",
            "port" => 9090,
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
