defmodule KubeResources.PrometheusOperator do
  @moduledoc """
  This module is responsible for getting the prometheues operator all set up and running.

  This can generate a config and will also add on alerting/monitoring.
  """
  alias KubeResources.MonitoringSettings

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-prometheus-operator",
        "namespace" => namespace
      }
    }
  end

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-prometheus-operator"
      },
      "rules" => [
        %{
          "apiGroups" => ["monitoring.coreos.com"],
          "resources" => [
            "alertmanagers",
            "alertmanagers/finalizers",
            "alertmanagerconfigs",
            "prometheuses",
            "prometheuses/finalizers",
            "thanosrulers",
            "thanosrulers/finalizers",
            "servicemonitors",
            "podmonitors",
            "probes",
            "prometheusrules"
          ],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["apps"],
          "resources" => ["statefulsets"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps", "secrets"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["pods"],
          "verbs" => ["list", "delete"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["services", "services/finalizers", "endpoints"],
          "verbs" => ["get", "create", "update", "delete"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["nodes"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["namespaces"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
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
          "battery/app" => "prometheus-operator",
          "battery/managed" => "True"
        },
        "name" => "battery-prometheus-operator"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-prometheus-operator"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-prometheus-operator",
          "namespace" => namespace
        }
      ]
    }
  end

  def deployment(config) do
    namespace = MonitoringSettings.namespace(config)
    image = MonitoringSettings.prometheus_operator_image(config)
    version = MonitoringSettings.prometheus_operator_version(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus-operator",
          "battery/managed" => "True"
        },
        "namespace" => namespace,
        "name" => "battery-prometheus-operator"
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "prometheus-operator",
            "battery/managed" => "True"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "prometheus-operator",
              "battery/managed" => "True"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--kubelet-service=kube-system/kubelet",
                  "--prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:#{version}"
                ],
                "image" => "#{image}:#{version}",
                "name" => "prometheus-operator",
                "ports" => [%{"containerPort" => 8080, "name" => "http"}],
                "resources" => %{
                  "limits" => %{"cpu" => "200m", "memory" => "200Mi"},
                  "requests" => %{"cpu" => "100m", "memory" => "100Mi"}
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false
                }
              },
              %{
                "args" => [
                  "--logtostderr",
                  "--secure-listen-address=:8443",
                  "--tls-cipher-suites=TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
                  "--upstream=http://127.0.0.1:8080/"
                ],
                "image" => "quay.io/brancz/kube-rbac-proxy:v0.8.0",
                "name" => "kube-rbac-proxy",
                "ports" => [%{"containerPort" => 8443, "name" => "https"}],
                "resources" => %{
                  "limits" => %{"cpu" => "20m", "memory" => "40Mi"},
                  "requests" => %{"cpu" => "10m", "memory" => "20Mi"}
                },
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
            "securityContext" => %{
              "runAsNonRoot" => true,
              "runAsUser" => 65_534
            },
            "serviceAccountName" => "battery-prometheus-operator"
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
          "battery/app" => "prometheus-operator",
          "battery/managed" => "True"
        },
        "name" => "prometheus-operator",
        "namespace" => namespace
      },
      "spec" => %{
        "clusterIP" => "None",
        "ports" => [
          %{
            "name" => "https",
            "port" => 8443,
            "targetPort" => "https"
          }
        ],
        "selector" => %{
          "battery/app" => "prometheus-operator",
          "battery/managed" => "True"
        }
      }
    }
  end
end
