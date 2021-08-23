defmodule KubeResources.Nginx do
  @moduledoc false

  alias KubeResources.NetworkSettings

  def service_account(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "app.kubernetes.io/component" => "controller",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx",
        "namespace" => namespace
      },
      "automountServiceAccountToken" => true
    }
  end

  def config_map(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "app.kubernetes.io/component" => "controller",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx-controller",
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
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx"
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps", "endpoints", "nodes", "pods", "secrets"],
          "verbs" => ["list", "watch"]
        },
        %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["get"]},
        %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["get", "list", "watch"]},
        %{
          "apiGroups" => ["extensions", "networking.k8s.io"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
        %{
          "apiGroups" => ["extensions", "networking.k8s.io"],
          "resources" => ["ingresses/status"],
          "verbs" => ["update"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingressclasses"],
          "verbs" => ["get", "list", "watch"]
        }
      ]
    }
  end

  def cluster_role_binding(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-ingress-nginx"
      },
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "battery-ingress-nginx", "namespace" => namespace}
      ]
    }
  end

  def role(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "app.kubernetes.io/component" => "controller",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx",
        "namespace" => namespace
      },
      "rules" => [
        %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get"]},
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps", "pods", "secrets", "endpoints"],
          "verbs" => ["get", "list", "watch"]
        },
        %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["get", "list", "watch"]},
        %{
          "apiGroups" => ["extensions", "networking.k8s.io"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["extensions", "networking.k8s.io"],
          "resources" => ["ingresses/status"],
          "verbs" => ["update"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingressclasses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "resourceNames" => ["ingress-controller-leader-battery-nginx"],
          "verbs" => ["get", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["create"]},
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
      ]
    }
  end

  def role_binding(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "app.kubernetes.io/component" => "controller",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx",
        "namespace" => namespace
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "battery-ingress-nginx"
      },
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "battery-ingress-nginx", "namespace" => namespace}
      ]
    }
  end

  def service(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "app.kubernetes.io/component" => "controller",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx-controller",
        "namespace" => namespace
      },
      "spec" => %{
        "type" => "LoadBalancer",
        "ports" => [
          %{"name" => "http", "port" => 80, "protocol" => "TCP", "targetPort" => "http"},
          %{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => "https"}
        ],
        "selector" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/component" => "controller"
        }
      }
    }
  end

  def deployment(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "ingress-nginx",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "0.48.1",
          "app.kubernetes.io/component" => "controller",
          "battery/managed" => "True"
        },
        "name" => "battery-ingress-nginx-controller",
        "namespace" => namespace
      },
      "spec" => %{
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "ingress-nginx",
            "app.kubernetes.io/instance" => "battery",
            "app.kubernetes.io/component" => "controller"
          }
        },
        "replicas" => 1,
        "revisionHistoryLimit" => 10,
        "minReadySeconds" => 0,
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "ingress-nginx",
              "app.kubernetes.io/instance" => "battery",
              "app.kubernetes.io/component" => "controller",
              "battery/managed" => "True"
            }
          },
          "spec" => %{
            "dnsPolicy" => "ClusterFirst",
            "containers" => [
              %{
                "name" => "controller",
                "image" =>
                  "k8s.gcr.io/ingress-nginx/controller:v0.48.1@sha256:e9fb216ace49dfa4a5983b183067e97496e7a8b307d2093f4278cd550c303899",
                "imagePullPolicy" => "IfNotPresent",
                "lifecycle" => %{"preStop" => %{"exec" => %{"command" => ["/wait-shutdown"]}}},
                "args" => [
                  "/nginx-ingress-controller",
                  "--publish-service=$(POD_NAMESPACE)/battery-ingress-nginx-controller",
                  "--election-id=ingress-controller-leader",
                  "--ingress-class=battery-nginx",
                  "--configmap=$(POD_NAMESPACE)/battery-ingress-nginx-controller"
                ],
                "securityContext" => %{
                  "capabilities" => %{"drop" => ["ALL"], "add" => ["NET_BIND_SERVICE"]},
                  "runAsUser" => 101,
                  "allowPrivilegeEscalation" => true
                },
                "env" => [
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{"name" => "LD_PRELOAD", "value" => "/usr/local/lib/libmimalloc.so"}
                ],
                "livenessProbe" => %{
                  "failureThreshold" => 5,
                  "httpGet" => %{"path" => "/healthz", "port" => 10_254, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 10,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/healthz", "port" => 10_254, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 10,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "ports" => [
                  %{"name" => "http", "containerPort" => 80, "protocol" => "TCP"},
                  %{"name" => "https", "containerPort" => 443, "protocol" => "TCP"}
                ],
                "resources" => %{"requests" => %{"cpu" => "100m", "memory" => "90Mi"}}
              }
            ],
            "nodeSelector" => %{"kubernetes.io/os" => "linux"},
            "serviceAccountName" => "battery-ingress-nginx",
            "terminationGracePeriodSeconds" => 300
          }
        }
      }
    }
  end
end
