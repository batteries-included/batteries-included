defmodule KubeResources.Kong do
  @moduledoc false

  alias KubeResources.NetworkSettings

  @crd_path "priv/manifests/kong/crd.yaml"

  def crd(_), do: yaml(crd_content())

  def service_account(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-kong",
        "namespace" => namespace,
        "labels" => %{
          "app.kubernetes.io/name" => "kong",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "2.5",
          "battery/managed" => "True"
        }
      }
    }
  end

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/name" => "kong",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "2.5",
          "battery/managed" => "True"
        },
        "name" => "battery-kong"
      },
      "rules" => [
        %{"apiGroups" => [""], "resources" => ["endpoints"], "verbs" => ["list", "watch"]},
        %{
          "apiGroups" => [""],
          "resources" => ["endpoints/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
        %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["list", "watch"]},
        %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["get", "list", "watch"]},
        %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["list", "watch"]},
        %{
          "apiGroups" => [""],
          "resources" => ["secrets/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["get", "list", "watch"]},
        %{
          "apiGroups" => [""],
          "resources" => ["services/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["kongclusterplugins"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["kongclusterplugins/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["kongconsumers"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["kongconsumers/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["kongingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["kongingresses/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["kongplugins"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["kongplugins/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["tcpingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["tcpingresses/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["udpingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["configuration.konghq.com"],
          "resources" => ["udpingresses/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["extensions"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["extensions"],
          "resources" => ["ingresses/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["networking.internal.knative.dev"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["networking.internal.knative.dev"],
          "resources" => ["ingresses/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingresses/status"],
          "verbs" => ["get", "patch", "update"]
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
        "name" => "battery-kong",
        "labels" => %{
          "app.kubernetes.io/name" => "kong",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "2.5",
          "battery/managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-kong"
      },
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "battery-kong", "namespace" => namespace}
      ]
    }
  end

  def role(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "name" => "battery-kong",
        "namespace" => namespace,
        "labels" => %{
          "app.kubernetes.io/name" => "kong",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "2.5",
          "battery/managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps", "pods", "secrets", "namespaces"],
          "verbs" => ["get"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "resourceNames" => ["kong-ingress-controller-leader-kong-kong"],
          "verbs" => ["get", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["create"]},
        %{"apiGroups" => [""], "resources" => ["endpoints"], "verbs" => ["get"]},
        %{
          "apiGroups" => ["", "coordination.k8s.io"],
          "resources" => ["configmaps", "leases"],
          "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
        },
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
        %{"apiGroups" => [""], "resources" => ["services", "endpoints"], "verbs" => ["get"]}
      ]
    }
  end

  def role_binding(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "name" => "battery-kong",
        "namespace" => namespace,
        "labels" => %{
          "app.kubernetes.io/name" => "kong",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "2.5",
          "battery/managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "battery-kong"
      },
      "subjects" => [
        %{"kind" => "ServiceAccount", "name" => "battery-kong", "namespace" => namespace}
      ]
    }
  end

  def service(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => "battery-kong-proxy",
        "namespace" => namespace,
        "labels" => %{
          "app.kubernetes.io/name" => "kong",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "2.5",
          "enable-metrics" => "true",
          "battery/managed" => "True"
        }
      },
      "spec" => %{
        "type" => "LoadBalancer",
        "ports" => [
          %{"name" => "kong-proxy", "port" => 80, "targetPort" => 8000, "protocol" => "TCP"},
          %{"name" => "kong-proxy-tls", "port" => 443, "targetPort" => 8443, "protocol" => "TCP"}
        ],
        "selector" => %{
          "app.kubernetes.io/name" => "kong",
          "app.kubernetes.io/component" => "app",
          "app.kubernetes.io/instance" => "battery"
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
        "name" => "battery-kong",
        "namespace" => namespace,
        "labels" => %{
          "app.kubernetes.io/name" => "kong",
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/version" => "2.5",
          "app.kubernetes.io/component" => "app",
          "battery/managed" => "True"
        },
        "annotations" => %{
          "kuma.io/gateway" => "enabled",
          "traffic.sidecar.istio.io/includeInboundPorts" => ""
        }
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/name" => "kong",
            "app.kubernetes.io/component" => "app",
            "app.kubernetes.io/instance" => "battery"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app.kubernetes.io/name" => "kong",
              "app.kubernetes.io/instance" => "battery",
              "app.kubernetes.io/version" => "2.5",
              "app.kubernetes.io/component" => "app",
              "battery/managed" => "True"
            }
          },
          "spec" => %{
            "automountServiceAccountToken" => true,
            "serviceAccountName" => "battery-kong",
            "containers" => [
              %{
                "name" => "ingress-controller",
                "securityContext" => %{},
                "args" => ["/kong-ingress-controller"],
                "env" => [
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{
                      "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.name"}
                    }
                  },
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{
                      "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.namespace"}
                    }
                  },
                  %{
                    "name" => "CONTROLLER_ELECTION_ID",
                    "value" => "kong-ingress-controller-leader-kong"
                  },
                  %{"name" => "CONTROLLER_INGRESS_CLASS", "value" => "kong"},
                  %{"name" => "CONTROLLER_KONG_ADMIN_TLS_SKIP_VERIFY", "value" => "true"},
                  %{"name" => "CONTROLLER_KONG_ADMIN_URL", "value" => "https://localhost:8444"},
                  %{
                    "name" => "CONTROLLER_PUBLISH_SERVICE",
                    "value" => "#{namespace}/battery-kong-proxy"
                  }
                ],
                "image" => "kong/kubernetes-ingress-controller:1.3",
                "imagePullPolicy" => "IfNotPresent",
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/healthz", "port" => 10_254, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 5
                },
                "livenessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/healthz", "port" => 10_254, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 5
                },
                "resources" => %{}
              },
              %{
                "name" => "proxy",
                "image" => "kong:2.5",
                "imagePullPolicy" => "IfNotPresent",
                "securityContext" => %{},
                "env" => [
                  %{"name" => "KONG_ADMIN_ACCESS_LOG", "value" => "/dev/stdout"},
                  %{"name" => "KONG_ADMIN_ERROR_LOG", "value" => "/dev/stderr"},
                  %{"name" => "KONG_ADMIN_GUI_ACCESS_LOG", "value" => "/dev/stdout"},
                  %{"name" => "KONG_ADMIN_GUI_ERROR_LOG", "value" => "/dev/stderr"},
                  %{"name" => "KONG_ADMIN_LISTEN", "value" => "127.0.0.1:8444 http2 ssl"},
                  %{"name" => "KONG_CLUSTER_LISTEN", "value" => "off"},
                  %{"name" => "KONG_DATABASE", "value" => "off"},
                  %{"name" => "KONG_KIC", "value" => "on"},
                  %{"name" => "KONG_LUA_PACKAGE_PATH", "value" => "/opt/?.lua;/opt/?/init.lua;;"},
                  %{"name" => "KONG_NGINX_WORKER_PROCESSES", "value" => "2"},
                  %{"name" => "KONG_PLUGINS", "value" => "bundled"},
                  %{"name" => "KONG_PORTAL_API_ACCESS_LOG", "value" => "/dev/stdout"},
                  %{"name" => "KONG_PORTAL_API_ERROR_LOG", "value" => "/dev/stderr"},
                  %{"name" => "KONG_PORT_MAPS", "value" => "80:8000, 443:8443"},
                  %{"name" => "KONG_PREFIX", "value" => "/kong_prefix/"},
                  %{"name" => "KONG_PROXY_ACCESS_LOG", "value" => "/dev/stdout"},
                  %{"name" => "KONG_PROXY_ERROR_LOG", "value" => "/dev/stderr"},
                  %{
                    "name" => "KONG_PROXY_LISTEN",
                    "value" => "0.0.0.0:8000, 0.0.0.0:8443 http2 ssl"
                  },
                  %{"name" => "KONG_STATUS_LISTEN", "value" => "0.0.0.0:8100"},
                  %{"name" => "KONG_STREAM_LISTEN", "value" => "off"},
                  %{"name" => "KONG_NGINX_DAEMON", "value" => "off"}
                ],
                "lifecycle" => %{
                  "preStop" => %{
                    "exec" => %{"command" => ["/bin/sh", "-c", "/bin/sleep 15 && kong quit"]}
                  }
                },
                "ports" => [
                  %{"name" => "proxy", "containerPort" => 8000, "protocol" => "TCP"},
                  %{"name" => "proxy-tls", "containerPort" => 8443, "protocol" => "TCP"},
                  %{"name" => "status", "containerPort" => 8100, "protocol" => "TCP"}
                ],
                "volumeMounts" => [
                  %{"name" => "battery-kong-prefix-dir", "mountPath" => "/kong_prefix/"},
                  %{"name" => "battery-kong-tmp", "mountPath" => "/tmp"}
                ],
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/status", "port" => "status", "scheme" => "HTTP"},
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 5
                },
                "livenessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/status", "port" => "status", "scheme" => "HTTP"},
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 5
                },
                "resources" => %{}
              }
            ],
            "securityContext" => %{},
            "terminationGracePeriodSeconds" => 30,
            "tolerations" => [],
            "volumes" => [
              %{"name" => "battery-kong-prefix-dir", "emptyDir" => %{}},
              %{"name" => "battery-kong-tmp", "emptyDir" => %{}}
            ]
          }
        }
      }
    }
  end

  def pod(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Pod",
      "metadata" => %{
        "name" => "battery-test-ingress",
        "annotations" => %{},
        "namespace" => namespace
      },
      "spec" => %{
        "restartPolicy" => "OnFailure",
        "containers" => [
          %{
            "name" => "battery-curl",
            "image" => "curlimages/curl",
            "command" => [
              "curl",
              base_path(namespace) <> "/httpbin"
            ]
          }
        ]
      }
    }
  end

  def pod_1(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Pod",
      "metadata" => %{
        "name" => "battery-test-ingress-v1beta1",
        "annotations" => %{},
        "namespace" => namespace
      },
      "spec" => %{
        "restartPolicy" => "OnFailure",
        "containers" => [
          %{
            "name" => "battery-curl",
            "image" => "curlimages/curl",
            "command" => [
              "curl",
              base_path(namespace) <> "/httpbin-v1beta1"
            ]
          }
        ]
      }
    }
  end

  def base_path(namespace), do: "http://battery-kong-proxy.#{namespace}.svc.cluster.local"

  defp crd_content, do: unquote(File.read!(@crd_path))

  defp yaml(content) do
    content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate_content_hash/1)
  end
end
