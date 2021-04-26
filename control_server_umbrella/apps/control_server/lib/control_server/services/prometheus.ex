defmodule ControlServer.Services.Prometheus do
  @moduledoc """
  This module contains all the code to interact with, including starting, prometheuses.any()

  Currently this is around config generation via Monitoring.materialize/1
  """
  @prometheus_version "v2.22.1"
  @prometheus_name "prometheus-main"
  @prometheus_account "prometheus-battery-account"
  @prometheus_main_role "prometheus-battery-main-role"
  @prometheus_cluster_role "prometheus-battery-cluster-role"
  @prometheus_config_role "prometheus-battery-config-role"

  @requested_memory "400Mi"
  @replicas 1

  def prometheus(prometheus_ns) do
    %{
      "apiVersion" => "monitoring.coreos.com/v1",
      "kind" => "Prometheus",
      "metadata" => %{
        "labels" => %{
          "prometheus" => @prometheus_name
        },
        "name" => @prometheus_name,
        "namespace" => prometheus_ns
      },
      "spec" => %{
        # "alerting" => %{
        #   "alertmanagers" => [
        #     %{
        #       "name" => "alertmanager-main",
        #       "namespace" => prometheus_ns,
        #       "port" => "web"
        #     }
        #   ]
        # },
        "image" => "quay.io/prometheus/prometheus:#{@prometheus_version}",
        "nodeSelector" => %{
          "kubernetes.io/os": "linux"
        },

        # select everything.
        "podMonitorNamespaceSelector" => %{},
        "podMonitorSelector" => %{},
        "probeNamespaceSelector" => %{},
        "probeSelector" => %{},
        "replicas" => @replicas,
        "resources" => %{
          "requests" => %{
            "memory" => @requested_memory
          }
        },
        "ruleSelector" => %{
          "matchLabels" => %{
            "prometheus" => @prometheus_name,
            "role" => "alert-rules"
          }
        },
        "securityContext" => %{
          "fsGroup" => 2000,
          "runAsNonRoot" => true,
          "runAsUser" => 1000
        },
        "serviceAccountName" => @prometheus_account,
        "serviceMonitorNamespaceSelector" => %{},
        "serviceMonitorSelector" => %{},
        "version" => @prometheus_version
      }
    }
  end

  def service(prometheus_ns) do
    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "prometheus" => @prometheus_name
        },
        "name" => @prometheus_name,
        "namespace" => prometheus_ns
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
          "app" => "prometheus",
          "prometheus" => @prometheus_name
        },
        "sessionAffinity" => "ClientIP"
      }
    }
  end

  def service_account(prometheus_ns) do
    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => @prometheus_account,
        "namespace" => prometheus_ns
      }
    }
  end

  def role(:cluster) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{"name" => @prometheus_cluster_role},
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

  def role(:config, prometheus_ns) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{"name" => @prometheus_config_role, "namespace" => prometheus_ns},
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "verbs" => ["get"]
        }
      ]
    }
  end

  def role(:main, namespace) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{"name" => @prometheus_main_role, "namespace" => namespace},
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

  def role_binding(:config, prometheus_ns) do
    metadata = %{
      "name" => @prometheus_config_role,
      "namespace" => prometheus_ns
    }

    gen_role_binding(@prometheus_config_role, prometheus_ns, metadata)
  end

  def role_binding(:cluster, prometheus_ns) do
    metadata = %{
      "name" => @prometheus_cluster_role
    }

    gen_role_binding(@prometheus_cluster_role, prometheus_ns, metadata, "ClusterRole")
  end

  def role_binding(:main, namespace, prometheus_ns) do
    metadata = %{
      "name" => @prometheus_main_role,
      "namespace" => namespace
    }

    gen_role_binding(@prometheus_main_role, prometheus_ns, metadata)
  end

  defp gen_role_binding(role_name, prometheus_ns, %{} = metadata, role_type \\ "Role") do
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
          "name" => @prometheus_account,
          "namespace" => prometheus_ns
        }
      ]
    }
  end
end
