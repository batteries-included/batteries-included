defmodule ControlServer.Services.PrometheusOperator do
  @moduledoc """
  This module is responsible for getting the prometheues operator all set up and running.

  This can generate a config and will also add on alerting/monitoring.
  """
  @operator_name "battery-prometheus-operator"
  @operator_account_name "prometheus-operator-battery-account"
  @operator_role_name "prometheus-operator-battery-role"
  @operator_version "v0.44.1"

  def service_account(namespace_name) do
    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component": "controller",
          "app.kubernetes.io/name": @operator_name,
          "app.kubernetes.io/version": @operator_version
        },
        "name" => @operator_account_name,
        "namespace" => namespace_name
      }
    }
  end

  def cluster_role do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component": "controller",
          "app.kubernetes.io/name": @operator_name,
          "app.kubernetes.io/version": @operator_version
        },
        "name" => @operator_role_name
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

  def cluster_role_binding(namespace_name) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component": "controller",
          "app.kubernetes.io/name": @operator_name,
          "app.kubernetes.io/version": @operator_version
        },
        "name" => @operator_name
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => @operator_role_name
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => @operator_account_name,
          "namespace" => namespace_name
        }
      ]
    }
  end

  def deployment(namespace_name) do
    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component": "controller",
          "app.kubernetes.io/name": @operator_name,
          "app.kubernetes.io/version": @operator_version
        },
        "name" => @operator_name,
        "namespace" => namespace_name
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/component": "controller",
            "app.kubernetes.io/name": @operator_name
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app.kubernetes.io/component": "controller",
              "app.kubernetes.io/name": @operator_name,
              "app.kubernetes.io/version": @operator_version
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--kubelet-service=kube-system/kubelet",
                  "--prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:#{
                    @operator_version
                  }"
                ],
                "image" => "quay.io/prometheus-operator/prometheus-operator:#{@operator_version}",
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
            "serviceAccountName" => @operator_account_name
          }
        }
      }
    }
  end

  def service(namespace_name) do
    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component": "controller",
          "app.kubernetes.io/name": @operator_name,
          "app.kubernetes.io/version": @operator_version
        },
        "name" => @operator_name,
        "namespace" => namespace_name
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
          "app.kubernetes.io/component": "controller",
          "app.kubernetes.io/name": @operator_name
        }
      }
    }
  end
end
