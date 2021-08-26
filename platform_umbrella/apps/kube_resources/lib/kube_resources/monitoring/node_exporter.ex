defmodule KubeResources.NodeExporter do
  @moduledoc """
  Module for controlling the node exporter pods that will be needed to send metrics to prometheus.
  """
  alias KubeResources.MonitoringSettings
  alias KubeResources.RBAC

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-node-exporter",
        "labels" => %{
          "battery/app" => "node-exporter",
          "battery/managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["authentication.k8s.io"],
          "resources" => ["tokenreviews"],
          "verbs" => ["create"]
        },
        %{
          "apiGroups" => ["authorization.k8s.io"],
          "resources" => ["subjectaccessreviews"],
          "verbs" => ["create"]
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
          "battery/app" => "node-exporter",
          "battery/managed" => "True"
        },
        "name" => "battery-node-exporter",
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
          "battery/app" => "node-exporter",
          "battery/managed" => "True"
        },
        "name" => "battery-node-exporter"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-node-exporter"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-node-exporter",
          "namespace" => namespace
        }
      ]
    }
  end

  def daemonset(config) do
    namespace = MonitoringSettings.namespace(config)
    version = MonitoringSettings.node_version(config)
    image = MonitoringSettings.node_image(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "DaemonSet",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "node-exporter",
          "battery/managed" => "True"
        },
        "name" => "node-exporter",
        "namespace" => namespace
      },
      "spec" => %{
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "node-exporter"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "node-exporter",
              "battery/managed" => "True"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--web.listen-address=127.0.0.1:9100",
                  "--path.procfs=/host/proc",
                  "--path.sysfs=/host/sys",
                  "--path.rootfs=/host/root",
                  "--no-collector.wifi",
                  "--no-collector.hwmon",
                  "--collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/pods/.+)($|/)"
                ],
                "image" => "#{image}:#{version}",
                "name" => "node-exporter",
                "resources" => %{
                  "limits" => %{
                    "cpu" => "250m",
                    "memory" => "180Mi"
                  },
                  "requests" => %{
                    "cpu" => "102m",
                    "memory" => "180Mi"
                  }
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/host/proc",
                    # "mountPropagation" => "HostToContainer",
                    "name" => "proc",
                    "readOnly" => true
                  },
                  %{
                    "mountPath" => "/host/sys",
                    # "mountPropagation" => "HostToContainer",
                    "name" => "sys",
                    "readOnly" => true
                  },
                  %{
                    "mountPath" => "/host/root",
                    # "mountPropagation" => "HostToContainer",
                    "name" => "root",
                    "readOnly" => true
                  }
                ]
              },
              RBAC.host_proxy_container("http://127.0.0.1:9100/", 9100, "https")
            ],
            "hostNetwork" => true,
            "hostPID" => true,
            "nodeSelector" => %{
              "kubernetes.io/os": "linux"
            },
            "securityContext" => %{
              "runAsNonRoot" => true,
              "runAsUser" => 65_534
            },
            "serviceAccountName" => "battery-node-exporter",
            "tolerations" => [
              %{
                "operator" => "Exists"
              }
            ],
            "volumes" => [
              %{
                "hostPath" => %{
                  "path" => "/proc"
                },
                "name" => "proc"
              },
              %{
                "hostPath" => %{
                  "path" => "/sys"
                },
                "name" => "sys"
              },
              %{
                "hostPath" => %{
                  "path" => "/"
                },
                "name" => "root"
              }
            ]
          }
        },
        "updateStrategy" => %{
          "rollingUpdate" => %{
            "maxUnavailable" => "10%"
          },
          "type" => "RollingUpdate"
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
          "battery/app" => "node-exporter",
          "battery/managed" => "True"
        },
        "name" => "node-exporter",
        "namespace" => namespace
      },
      "spec" => %{
        "clusterIP" => "None",
        "ports" => [
          %{
            "name" => "https",
            "port" => 9100,
            "targetPort" => "https"
          }
        ],
        "selector" => %{
          "battery/app" => "node-exporter"
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
            "battery/app" => "node-exporter",
            "battery/managed" => "True"
          },
          "name" => "node-exporter",
          "namespace" => namespace
        },
        "spec" => %{
          "endpoints" => [
            %{
              "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
              "interval" => "15s",
              "port" => "https",
              "relabelings" => [
                %{
                  "action" => "replace",
                  "regex" => "(.*)",
                  "replacement" => "$1",
                  "sourceLabels" => ["__meta_kubernetes_pod_node_name"],
                  "targetLabel" => "instance"
                }
              ],
              "scheme" => "https",
              "tlsConfig" => %{"insecureSkipVerify" => true}
            }
          ],
          "jobLabel" => "battery/app",
          "selector" => %{
            "matchLabels" => %{
              "battery/app" => "node-exporter"
            }
          }
        }
      }
    ]
  end
end
