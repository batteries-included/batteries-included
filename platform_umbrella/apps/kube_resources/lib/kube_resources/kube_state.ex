defmodule KubeResources.KubeState do
  @moduledoc """
  Module to keep the KubeState deployment up and configured.
  """
  alias KubeResources.MonitoringSettings

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "kube-state-metrics",
          "battery/managed" => "True"
        },
        "name" => "battery-kube-state-metrics"
      },
      "rules" => [
        %{
          "apiGroups" => [
            ""
          ],
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
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "extensions"
          ],
          "resources" => [
            "daemonsets",
            "deployments",
            "replicasets",
            "ingresses"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "apps"
          ],
          "resources" => [
            "statefulsets",
            "daemonsets",
            "deployments",
            "replicasets"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "batch"
          ],
          "resources" => [
            "cronjobs",
            "jobs"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "autoscaling"
          ],
          "resources" => [
            "horizontalpodautoscalers"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "authentication.k8s.io"
          ],
          "resources" => [
            "tokenreviews"
          ],
          "verbs" => [
            "create"
          ]
        },
        %{
          "apiGroups" => [
            "authorization.k8s.io"
          ],
          "resources" => [
            "subjectaccessreviews"
          ],
          "verbs" => [
            "create"
          ]
        },
        %{
          "apiGroups" => [
            "policy"
          ],
          "resources" => [
            "poddisruptionbudgets"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "certificates.k8s.io"
          ],
          "resources" => [
            "certificatesigningrequests"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "storage.k8s.io"
          ],
          "resources" => [
            "storageclasses",
            "volumeattachments"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "admissionregistration.k8s.io"
          ],
          "resources" => [
            "mutatingwebhookconfigurations",
            "validatingwebhookconfigurations"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            "networking.k8s.io"
          ],
          "resources" => [
            "networkpolicies"
          ],
          "verbs" => [
            "list",
            "watch"
          ]
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
          "battery/managed" => "True"
        },
        "name" => "kube-state-metrics",
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
          "battery/managed" => "True"
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
          "battery/managed" => "True"
        },
        "name" => "kube-state-metrics",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "kube-state-metrics",
            "battery/managed" => "True"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "kube-state-metrics",
              "battery/managed" => "True"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--host=127.0.0.1",
                  "--port=8081",
                  "--telemetry-host=127.0.0.1",
                  "--telemetry-port=8082"
                ],
                "image" => "#{image}:#{version}",
                "name" => "kube-state-metrics"
              },
              %{
                "args" => [
                  "--logtostderr",
                  "--secure-listen-address=:8443",
                  "--tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
                  "--upstream=http://127.0.0.1:8081/"
                ],
                "image" => "quay.io/brancz/kube-rbac-proxy:v0.8.0",
                "name" => "kube-rbac-proxy-main",
                "ports" => [
                  %{
                    "containerPort" => 8443,
                    "name" => "https-main"
                  }
                ],
                "securityContext" => %{
                  "runAsGroup" => 65_532,
                  "runAsNonRoot" => true,
                  "runAsUser" => 65_532
                }
              },
              %{
                "args" => [
                  "--logtostderr",
                  "--secure-listen-address=:9443",
                  "--tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
                  "--upstream=http://127.0.0.1:8082/"
                ],
                "image" => "quay.io/brancz/kube-rbac-proxy:v0.8.0",
                "name" => "kube-rbac-proxy-self",
                "ports" => [
                  %{
                    "containerPort" => 9443,
                    "name" => "https-self"
                  }
                ],
                "securityContext" => %{
                  "runAsGroup" => 65_532,
                  "runAsNonRoot" => true,
                  "runAsUser" => 65_532
                }
              }
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
        "name" => "kube-state-metrics",
        "namespace" => namespace
      },
      "spec" => %{
        "clusterIP" => "None",
        "ports" => [
          %{
            "name" => "https-main",
            "port" => 8443,
            "targetPort" => "https-main"
          },
          %{
            "name" => "https-self",
            "port" => 9443,
            "targetPort" => "https-self"
          }
        ],
        "selector" => %{
          "battery/app" => "kube-state-metrics",
          "battery/managed" => "True"
        }
      }
    }
  end
end
