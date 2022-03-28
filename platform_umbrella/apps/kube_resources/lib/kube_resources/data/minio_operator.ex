defmodule KubeResources.MinioOperator do
  @moduledoc false

  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeRawResources.DataSettings

  @app "minio-operator"

  @console_service_account "minio-console"
  @operator_service_account "minio-operator"

  @console_port 8989
  @console_tls_port 5777
  @operator_port 6006

  @operator_cluster_role "battery-minio-operator"
  @console_cluster_role "battery-minio-operator"

  @operator_service "minio-operator"

  @crd_path "priv/manifests/minio/minio.crds.yaml"

  def materialize(config) do
    %{
      "/crd" => crd(config),
      "/service_account_console" => service_account_console(config),
      "/config_map_console" => config_map_console(config),
      "/cluster_role_console" => cluster_role_console(config),
      "/cluster_role_binding_console" => cluster_role_binding_console(config),
      "/service_console" => service_console(config),
      "/deployment_console" => deployment_console(config),
      "/service_account_operator" => service_account_operator(config),
      "/cluster_role_operator" => cluster_role_operator(config),
      "/cluster_role_binding_operator" => cluster_role_binding_operator(config),
      "/service_operator" => service_operator(config),
      "/deployment_operator" => deployment_operator(config)
    }
  end

  def crd(config) do
    namespace = DataSettings.namespace(config)

    crd_content()
    |> yaml()
    |> Enum.at(0)
    |> update_in(["spec", "conversion", "webhook", "clientConfig", "service"], fn v ->
      Map.merge(v , %{
        "name" => @operator_service,
        "namespace" => namespace,
        "port" => @operator_port
      })
    end)
  end

  def service_account_console(config) do
    namespace = DataSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name(@console_service_account)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def service_account_operator(config) do
    namespace = DataSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name(@operator_service_account)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def config_map_console(config) do
    namespace = DataSettings.namespace(config)

    port_values = %{
      "CONSOLE_PORT" => "#{@console_port}",
      "CONSOLE_TLS_PORT" => "#{@console_tls_port}"
    }

    B.build_resource(:config_map)
    |> B.name("console-env")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> Map.put("data", port_values)
  end

  def cluster_role_operator(_config) do
    rules = [
      %{
        "apiGroups" => [
          "apiextensions.k8s.io"
        ],
        "resources" => [
          "customresourcedefinitions"
        ],
        "verbs" => [
          "get",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "persistentvolumeclaims"
        ],
        "verbs" => [
          "get",
          "update",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "namespaces"
        ],
        "verbs" => [
          "get",
          "watch",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "pods",
          "services",
          "events",
          "configmaps"
        ],
        "verbs" => [
          "get",
          "watch",
          "patch",
          "create",
          "list",
          "delete",
          "deletecollection",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "watch",
          "create",
          "update",
          "list",
          "delete",
          "deletecollection"
        ]
      },
      %{
        "apiGroups" => [
          "apps"
        ],
        "resources" => [
          "statefulsets",
          "deployments"
        ],
        "verbs" => [
          "get",
          "create",
          "list",
          "patch",
          "watch",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "batch"
        ],
        "resources" => [
          "jobs"
        ],
        "verbs" => [
          "get",
          "create",
          "list",
          "patch",
          "watch",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "certificates.k8s.io"
        ],
        "resources" => [
          "certificatesigningrequests",
          "certificatesigningrequests/approval",
          "certificatesigningrequests/status"
        ],
        "verbs" => [
          "update",
          "create",
          "get",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "certificates.k8s.io"
        ],
        "resourceNames" => [
          "kubernetes.io/legacy-unknown",
          "kubernetes.io/kube-apiserver-client",
          "kubernetes.io/kubelet-serving"
        ],
        "resources" => [
          "signers"
        ],
        "verbs" => [
          "approve",
          "sign"
        ]
      },
      %{
        "apiGroups" => [
          "minio.min.io"
        ],
        "resources" => [
          "*"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "min.io"
        ],
        "resources" => [
          "*"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "monitoring.coreos.com"
        ],
        "resources" => [
          "prometheuses"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "get",
          "update",
          "create"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@operator_cluster_role)
    |> B.app_labels(@app)
    |> Map.put("rules", rules)
  end

  def cluster_role_console(_config) do
    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "watch",
          "create",
          "list",
          "patch",
          "update",
          "deletecollection"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "namespaces",
          "services",
          "events",
          "resourcequotas",
          "nodes"
        ],
        "verbs" => [
          "get",
          "watch",
          "create",
          "list",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "pods"
        ],
        "verbs" => [
          "get",
          "watch",
          "create",
          "list",
          "patch",
          "delete",
          "deletecollection"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "persistentvolumeclaims"
        ],
        "verbs" => [
          "deletecollection",
          "list",
          "get",
          "watch",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "storage.k8s.io"
        ],
        "resources" => [
          "storageclasses"
        ],
        "verbs" => [
          "get",
          "watch",
          "create",
          "list",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "apps"
        ],
        "resources" => [
          "statefulsets",
          "deployments"
        ],
        "verbs" => [
          "get",
          "create",
          "list",
          "patch",
          "watch",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "batch"
        ],
        "resources" => [
          "jobs"
        ],
        "verbs" => [
          "get",
          "create",
          "list",
          "patch",
          "watch",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "certificates.k8s.io"
        ],
        "resources" => [
          "certificatesigningrequests",
          "certificatesigningrequests/approval",
          "certificatesigningrequests/status"
        ],
        "verbs" => [
          "update",
          "create",
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "minio.min.io"
        ],
        "resources" => [
          "*"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          "min.io"
        ],
        "resources" => [
          "*"
        ],
        "verbs" => [
          "*"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "persistentvolumes"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "persistentvolumeclaims"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "list",
          "watch",
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "snapshot.storage.k8s.io"
        ],
        "resources" => [
          "volumesnapshots"
        ],
        "verbs" => [
          "get",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          "snapshot.storage.k8s.io"
        ],
        "resources" => [
          "volumesnapshotcontents"
        ],
        "verbs" => [
          "get",
          "list"
        ]
      },
      %{
        "apiGroups" => [
          "storage.k8s.io"
        ],
        "resources" => [
          "csinodes"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "storage.k8s.io"
        ],
        "resources" => [
          "volumeattachments"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "endpoints"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "direct.csi.min.io"
        ],
        "resources" => [
          "volumes"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "apiextensions.k8s.io"
        ],
        "resources" => [
          "customresourcedefinitions"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "direct.csi.min.io"
        ],
        "resources" => [
          "directcsidrives",
          "directcsivolumes"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "pod",
          "pods/log"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@console_cluster_role)
    |> B.app_labels(@app)
    |> Map.put("rules", rules)
  end

  def cluster_role_binding_operator(config) do
    namespace = DataSettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-minio-operator")
    |> B.app_labels(@app)
    |> Map.put("roleRef", B.build_cluster_role_ref(@operator_cluster_role))
    |> Map.put("subjects", [B.build_service_account(@operator_service_account, namespace)])
  end

  def cluster_role_binding_console(config) do
    namespace = DataSettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-minio-console")
    |> B.app_labels(@app)
    |> Map.put("roleRef", B.build_cluster_role_ref(@console_cluster_role))
    |> Map.put("subjects", [B.build_service_account(@console_service_account, namespace)])
  end

  def service_console(config) do
    namespace = DataSettings.namespace(config)

    spec = %{
      "ports" => [
        %{
          "name" => "http",
          "port" => @console_port
        },
        %{
          "name" => "https",
          "port" => @console_tls_port
        }
      ],
      "selector" => %{
        "battery/app" => @app,
        "battery/instance" => "console"
      }
    }

    B.build_resource(:service)
    |> B.name("minio-console")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def service_operator(config) do
    namespace = DataSettings.namespace(config)

    spec = %{
      "ports" => [
        %{
          "name" => "https",
          "port" => @operator_port
        }
      ],
      "selector" => %{
        "battery/app" => @app,
        "battery/instance" => "operator",
        "operator" => "leader"
      }
    }

    B.build_resource(:service)
    |> B.name(@operator_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def deployment_console(config) do
    namespace = DataSettings.namespace(config)

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app,
          "battery/instance" => "console"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app,
            "battery/instance" => "console",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "server"
              ],
              "env" => [
                %{
                  "name" => "CONSOLE_OPERATOR_MODE",
                  "value" => "on"
                }
              ],
              "image" => "minio/console:v0.14.8",
              "name" => "operator",
              "ports" => [
                %{
                  "containerPort" => @console_port,
                  "name" => "http"
                },
                %{
                  "containerPort" => @console_tls_port,
                  "name" => "https"
                }
              ]
            }
          ],
          "securityContext" => %{
            "runAsNonRoot" => true,
            "runAsUser" => 1000
          },
          "serviceAccountName" => @console_service_account
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("minio-console")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def deployment_operator(config) do
    namespace = DataSettings.namespace(config)

    spec = %{
      "replicas" => 2,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app,
          "battery/instance" => "operator"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app,
            "battery/instance" => "operator",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "affinity" => %{
            "podAntiAffinity" => %{
              "requiredDuringSchedulingIgnoredDuringExecution" => [
                %{
                  "labelSelector" => %{
                    "matchExpressions" => [
                      %{
                        "key" => "name",
                        "operator" => "In",
                        "values" => [
                          "minio-operator"
                        ]
                      }
                    ]
                  },
                  "topologyKey" => "kubernetes.io/hostname"
                }
              ]
            }
          },
          "containers" => [
            %{
              "image" => "minio/operator:v4.4.10",
              "name" => "operator",
              "resources" => %{
                "requests" => %{
                  "cpu" => "200m",
                  "ephemeral-storage" => "500Mi",
                  "memory" => "256Mi"
                }
              }
            }
          ],
          "securityContext" => %{
            "fsGroup" => 1000,
            "runAsGroup" => 1000,
            "runAsNonRoot" => true,
            "runAsUser" => 1000
          },
          "serviceAccountName" => @operator_service_account
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("minio-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  defp crd_content, do: unquote(File.read!(@crd_path))
end
