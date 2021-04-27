defmodule ControlServer.Services.Prometheus do
  @moduledoc """
  This module contains all the code to interact with, including starting, prometheuses.any()

  Currently this is around config generation via Monitoring.materialize/1
  """

  alias ControlServer.Services.MonitoringSettings

  def prometheus(config) do
    name = MonitoringSettings.prometheus_name(config)
    namespace = MonitoringSettings.namespace(config)
    account = MonitoringSettings.prometheus_account(config)

    image = MonitoringSettings.prometheus_image(config)
    version = MonitoringSettings.prometheus_version(config)

    memory = MonitoringSettings.prometheus_memory(config)
    replicas = MonitoringSettings.prometheus_replicas(config)

    %{
      "apiVersion" => "monitoring.coreos.com/v1",
      "kind" => "Prometheus",
      "metadata" => %{
        "labels" => %{
          "prometheus" => name
        },
        "name" => name,
        "namespace" => namespace
      },
      "spec" => %{
        # "alerting" => %{
        #   "alertmanagers" => [
        #     %{
        #       "name" => "alertmanager-main",
        #       "namespace" => monitoring_ns,
        #       "port" => "web"
        #     }
        #   ]
        # },
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
            "prometheus" => name,
            "role" => "alert-rules"
          }
        },
        "securityContext" => %{
          "fsGroup" => 2000,
          "runAsNonRoot" => true,
          "runAsUser" => 1000
        },
        "serviceAccountName" => account,
        "serviceMonitorNamespaceSelector" => %{},
        "serviceMonitorSelector" => %{},
        "version" => version
      }
    }
  end

  def service(config) do
    name = MonitoringSettings.prometheus_name(config)
    namespace = MonitoringSettings.namespace(config)

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
            "port" => 9090,
            "targetPort" => "web"
          }
        ],
        "selector" => %{
          "prometheus" => name
        },
        "sessionAffinity" => "ClientIP"
      }
    }
  end

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)
    account = MonitoringSettings.prometheus_account(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => account,
        "namespace" => namespace
      }
    }
  end

  def role(:cluster, config) do
    role = MonitoringSettings.prometheus_cluster_role(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{"name" => role},
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

  def role(:config, config) do
    role = MonitoringSettings.prometheus_config_role(config)
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{"name" => role, "namespace" => namespace},
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "verbs" => ["get"]
        }
      ]
    }
  end

  def role(:main, namespace, config) do
    role = MonitoringSettings.prometheus_config_role(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{"name" => role, "namespace" => namespace},
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
  end

  def role_binding(:config, config) do
    namespace = MonitoringSettings.namespace(config)
    role = MonitoringSettings.prometheus_config_role(config)
    account = MonitoringSettings.prometheus_account(config)

    metadata = %{
      "name" => role,
      "namespace" => namespace
    }

    gen_role_binding(role, namespace, metadata, account)
  end

  def role_binding(:cluster, config) do
    role = MonitoringSettings.prometheus_cluster_role(config)
    namespace = MonitoringSettings.namespace(config)
    account = MonitoringSettings.prometheus_account(config)

    metadata = %{
      "name" => role
    }

    gen_role_binding(role, namespace, metadata, account, "ClusterRole")
  end

  def role_binding(:main, namespace, config) do
    role = MonitoringSettings.prometheus_cluster_role(config)
    monitoring_namespace = MonitoringSettings.namespace(config)
    account = MonitoringSettings.prometheus_account(config)

    metadata = %{
      "name" => role,
      "namespace" => namespace
    }

    gen_role_binding(role, monitoring_namespace, metadata, account)
  end

  defp gen_role_binding(role_name, monitoring_ns, %{} = metadata, account, role_type \\ "Role") do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => role_type <> "Binding",
      "metadata" => metadata,
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => role_type,
        "name" => role_name
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => account,
          "namespace" => monitoring_ns
        }
      ]
    }
  end
end
