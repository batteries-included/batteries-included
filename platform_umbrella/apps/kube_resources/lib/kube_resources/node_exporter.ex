defmodule KubeResources.NodeExporter do
  @moduledoc """
  Module for controlling the node exporter pods that will be needed to send metrics to prometheus.
  """
  alias KubeResources.MonitoringSettings

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{"name" => "battery-node-exporter"},
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
          "battery/app" => "node-exporter"
        },
        "name" => "node-exporter",
        "namespace" => namespace
      },
      "spec" => %{
        "selector" => %{
          "matchLabels" => %{
            "battery/app": "node-exporter"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "node-exporter"
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
              %{
                "args" => [
                  "--logtostderr",
                  "--secure-listen-address=[$(IP)]:9100",
                  "--tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
                  "--upstream=http://127.0.0.1:9100/"
                ],
                "env" => [
                  %{
                    "name" => "IP",
                    "valueFrom" => %{
                      "fieldRef" => %{
                        "fieldPath" => "status.podIP"
                      }
                    }
                  }
                ],
                "image" => "quay.io/brancz/kube-rbac-proxy:v0.8.0",
                "name" => "kube-rbac-proxy",
                "ports" => [
                  %{
                    "containerPort" => 9100,
                    "hostPort" => 9100,
                    "name" => "https"
                  }
                ],
                "resources" => %{
                  "limits" => %{
                    "cpu" => "20m",
                    "memory" => "40Mi"
                  },
                  "requests" => %{
                    "cpu" => "10m",
                    "memory" => "20Mi"
                  }
                },
                "securityContext" => %{
                  "runAsGroup" => 65_532,
                  "runAsNonRoot" => true,
                  "runAsUser" => 65_532
                }
              }
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
end
