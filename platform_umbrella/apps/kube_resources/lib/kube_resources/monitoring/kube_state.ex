defmodule KubeResources.KubeStateMonitoring do
  @moduledoc """
  Module to keep the KubeState deployment up and configured.
  """
  alias KubeResources.MonitoringSettings
  alias KubeResources.RBAC

  @telemetry_port 9443
  @main_port 8443

  @telemetry_port_name "https-telemetry"
  @main_port_name "https-main"

  @internal_telemetry_port 8081
  @internal_main_port 8082

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "kube-state-metrics",
          "battery/managed" => "true"
        },
        "name" => "battery-kube-state-metrics"
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => [
            "configmaps",
            "secrets",
            "nodes",
            "pods",
            "services",
            "resourcequotas",
            "replicationcontrollers",
            "limitranges",
            "persistentvolumeclaims",
            "persistentvolumes",
            "namespaces",
            "endpoints"
          ],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["apps"],
          "resources" => ["statefulsets", "daemonsets", "deployments", "replicasets"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["batch"],
          "resources" => ["cronjobs", "jobs"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["autoscaling"],
          "resources" => ["horizontalpodautoscalers"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["authentication.k8s.io"],
          "resources" => ["tokenreviews"],
          "verbs" => ["create"]
        },
        %{
          "apiGroups" => ["authorization.k8s.io"],
          "resources" => ["subjectaccessreviews"],
          "verbs" => ["create"]
        },
        %{
          "apiGroups" => ["policy"],
          "resources" => ["poddisruptionbudgets"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["certificates.k8s.io"],
          "resources" => ["certificatesigningrequests"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["storage.k8s.io"],
          "resources" => ["storageclasses", "volumeattachments"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["admissionregistration.k8s.io"],
          "resources" => ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["networkpolicies", "ingresses"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => ["coordination.k8s.io"],
          "resources" => ["leases"],
          "verbs" => ["list", "watch"]
        }
      ]
    }
  end

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "kube-state-metrics",
          "battery/managed" => "true"
        },
        "name" => "battery-kube-state-metrics",
        "namespace" => namespace
      }
    }
  end

  def cluster_binding(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "kube-state-metrics",
          "battery/managed" => "true"
        },
        "name" => "battery-kube-state-metrics"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-kube-state-metrics"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-kube-state-metrics",
          "namespace" => namespace
        }
      ]
    }
  end

  def deployment(config) do
    namespace = MonitoringSettings.namespace(config)
    image = MonitoringSettings.kube_image(config)
    version = MonitoringSettings.kube_version(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "kube-state-metrics",
          "battery/managed" => "true"
        },
        "name" => "kube-state-metrics",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "kube-state-metrics"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "kube-state-metrics",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--host=127.0.0.1",
                  "--port=#{@internal_main_port}",
                  "--telemetry-host=127.0.0.1",
                  "--telemetry-port=#{@internal_telemetry_port}"
                ],
                "image" => "#{image}:#{version}",
                "name" => "kube-state-metrics"
              },
              RBAC.proxy_container(
                "http://127.0.0.1:#{@internal_main_port}/",
                @main_port,
                @main_port_name,
                "rbac-proxy-#{@main_port_name}"
              ),
              RBAC.proxy_container(
                "http://127.0.0.1:#{@internal_telemetry_port}/",
                @telemetry_port,
                @telemetry_port_name,
                "rbac-proxy-#{@telemetry_port_name}"
              )
            ],
            "nodeSelector" => %{
              "kubernetes.io/os": "linux"
            },
            "serviceAccountName" => "battery-kube-state-metrics"
          }
        }
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
          "battery/app" => "kube-state-metrics",
          "battery/managed" => "true"
        },
        "name" => "kube-state-metrics",
        "namespace" => namespace
      },
      "spec" => %{
        "clusterIP" => "None",
        "ports" => [
          %{
            "name" => @main_port_name,
            "port" => @main_port,
            "targetPort" => @main_port_name
          },
          %{
            "name" => @telemetry_port_name,
            "port" => @telemetry_port,
            "targetPort" => @telemetry_port_name
          }
        ],
        "selector" => %{
          "battery/app" => "kube-state-metrics"
        }
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
            "battery/app" => "kube-state-metrics",
            "battery/managed" => "true"
          },
          "name" => "kube-state-metrics",
          "namespace" => namespace
        },
        "spec" => %{
          "endpoints" => [
            %{
              "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
              "honorLabels" => true,
              "interval" => "30s",
              "port" => @main_port_name,
              "relabelings" => [
                %{"action" => "labeldrop", "regex" => "(pod|service|endpoint|namespace)"}
              ],
              "scheme" => "https",
              "scrapeTimeout" => "30s",
              "tlsConfig" => %{"insecureSkipVerify" => true}
            },
            %{
              "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
              "interval" => "30s",
              "port" => @telemetry_port_name,
              "scheme" => "https",
              "tlsConfig" => %{"insecureSkipVerify" => true}
            }
          ],
          "jobLabel" => "battery/app",
          "selector" => %{
            "matchLabels" => %{
              "battery/app" => "kube-state-metrics"
            }
          }
        }
      }
    ]
  end
end
