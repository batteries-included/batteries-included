defmodule KubeResources.Kong do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeResources.NetworkSettings

  @crd_path "priv/manifests/kong/crd.yaml"

  @app_name "kong"

  def materialize(config) do
    %{
      "/kong/0/crds" => crd(config),
      "/kong/1/service_account" => service_account(config),
      "/kong/1/cluster_role" => cluster_role(config),
      "/kong/1/cluster_role_binding" => cluster_role_binding(config),
      "/kong/1/role" => role(config),
      "/kong/1/role_binding" => role_binding(config),
      "/kong/1/service" => service(config),
      "/kong/1/service_1" => service_1(config),
      "/kong/1/deployment" => deployment(config),
      "/kong/1/pod" => pod(config),
      "/kong/1/pod_1" => pod_1(config),
      "/kong/1/pom_plugin" => prometheus_plugin(config)
    }
  end

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
          "battery/app" => @app_name,
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
          "battery/app" => @app_name,
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
          "battery/app" => @app_name,
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
          "battery/app" => @app_name,
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
          "resourceNames" => ["kong-ingress-controller-leader"],
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
          "battery/app" => @app_name,
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
        "name" => "kong-admin",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "True"
        }
      },
      "spec" => %{
        "type" => "NodePort",
        "ports" => [
          %{"name" => "kong-admin-tls", "port" => 8444, "targetPort" => 8444, "protocol" => "TCP"}
        ],
        "selector" => %{
          "battery/app" => @app_name
        }
      }
    }
  end

  def service_1(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => "kong-proxy",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => @app_name,
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
          "battery/app" => @app_name
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
        "name" => "kong",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "True",
          "enable-metrics" => "true"
        }
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => @app_name
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
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
                    "value" => "kong-ingress-controller-leader"
                  },
                  %{"name" => "CONTROLLER_INGRESS_CLASS", "value" => "kong"},
                  %{"name" => "CONTROLLER_KONG_ADMIN_TLS_SKIP_VERIFY", "value" => "true"},
                  %{"name" => "CONTROLLER_KONG_ADMIN_URL", "value" => "https://localhost:8444"},
                  %{
                    "name" => "CONTROLLER_PUBLISH_SERVICE",
                    "value" => "#{namespace}/kong-proxy"
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
                  %{"name" => "KONG_ADMIN_LISTEN", "value" => "0.0.0.0:8444 http2 ssl"},
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
                  %{"name" => "admin-tls", "containerPort" => 8444, "protocol" => "TCP"},
                  %{"name" => "proxy", "containerPort" => 8000, "protocol" => "TCP"},
                  %{"name" => "proxy-tls", "containerPort" => 8443, "protocol" => "TCP"},
                  %{"name" => "status", "containerPort" => 8100, "protocol" => "TCP"}
                ],
                "volumeMounts" => [
                  %{"name" => "kong-prefix-dir", "mountPath" => "/kong_prefix/"},
                  %{"name" => "kong-tmp", "mountPath" => "/tmp"}
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
              %{"name" => "kong-prefix-dir", "emptyDir" => %{}},
              %{"name" => "kong-tmp", "emptyDir" => %{}}
            ]
          }
        }
      }
    }
  end

  def monitors(%{"kong.install" => true} = config) do
    namespace = NetworkSettings.namespace(config)

    [
      %{
        "apiVersion" => "monitoring.coreos.com/v1",
        "kind" => "ServiceMonitor",
        "metadata" => %{
          "name" => "kong",
          "namespace" => namespace,
          "labels" => %{
            "battery/app" => @app_name,
            "battery/managed" => "True"
          }
        },
        "spec" => %{
          "endpoints" => [%{"targetPort" => "status", "scheme" => "http"}],
          "jobLabel" => "kong",
          "selector" => %{
            "matchLabels" => %{
              "battery/app" => @app_name
            }
          }
        }
      }
    ]
  end

  def monitors(_config), do: []

  def pod(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Pod",
      "metadata" => %{
        "name" => "test-ingress",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "True"
        }
      },
      "spec" => %{
        "restartPolicy" => "OnFailure",
        "containers" => [
          %{
            "name" => "curl",
            "image" => "curlimages/curl",
            "command" => ["curl", base_path(namespace) <> "/httpbin"]
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
        "name" => "test-ingress-v1beta1",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "True"
        }
      },
      "spec" => %{
        "restartPolicy" => "OnFailure",
        "containers" => [
          %{
            "name" => "kong-curl",
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

  def prometheus_plugin(_config) do
    B.build_resource("configuration.konghq.com/v1", "KongClusterPlugin")
    |> B.app_labels(@app_name)
    |> B.name("global-prometheus")
    |> B.annotation("kubernetes.io/ingress.class", "kong")
    |> B.label("global", "true")
    |> Map.put("plugin", "prometheus")
  end

  def base_path(namespace), do: "http://kong-proxy.#{namespace}.svc.cluster.local"

  defp crd_content, do: unquote(File.read!(@crd_path))

  defp yaml(content) do
    content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate_content_hash/1)
  end
end
