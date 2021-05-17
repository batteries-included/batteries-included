defmodule ControlServer.Services.PostgresOperator do
  @moduledoc false

  alias ControlServer.Settings.DatabaseSettings

  def service_account_0(config) do
    namespace = DatabaseSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-postgres-operator",
        "namespace" => namespace,
        "labels" => %{
          "app.kubernetes.io/name" => "postgres-operator",
          "app.kubernetes.io/instance" => "battery",
          "battery-managed" => "True"
        }
      }
    }
  end

  def cluster_role_0(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "postgres-pod",
        "labels" => %{
          "app.kubernetes.io/name" => "postgres-operator",
          "app.kubernetes.io/instance" => "battery",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["endpoints"],
          "verbs" => [
            "create",
            "delete",
            "deletecollection",
            "get",
            "list",
            "patch",
            "update",
            "watch"
          ]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["pods"],
          "verbs" => ["get", "list", "patch", "update", "watch"]
        },
        %{"apiGroups" => [""], "resources" => ["services"], "verbs" => ["create"]}
      ]
    }
  end

  def cluster_role_1(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-postgres-operator",
        "labels" => %{
          "app.kubernetes.io/name" => "postgres-operator",
          "app.kubernetes.io/instance" => "battery",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["acid.zalan.do"],
          "resources" => ["postgresqls", "postgresqls/status", "operatorconfigurations"],
          "verbs" => [
            "create",
            "delete",
            "deletecollection",
            "get",
            "list",
            "patch",
            "update",
            "watch"
          ]
        },
        %{
          "apiGroups" => ["acid.zalan.do"],
          "resources" => ["postgresteams"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["apiextensions.k8s.io"],
          "resources" => ["customresourcedefinitions"],
          "verbs" => ["create", "get", "patch", "update"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["events"],
          "verbs" => ["create", "get", "list", "patch", "update", "watch"]
        },
        %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["get"]},
        %{
          "apiGroups" => [""],
          "resources" => ["endpoints"],
          "verbs" => [
            "create",
            "delete",
            "deletecollection",
            "get",
            "list",
            "patch",
            "update",
            "watch"
          ]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["secrets"],
          "verbs" => ["create", "delete", "get", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["get", "list", "watch"]},
        %{
          "apiGroups" => [""],
          "resources" => ["persistentvolumeclaims"],
          "verbs" => ["delete", "get", "list", "patch", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["persistentvolumes"], "verbs" => ["get", "list"]},
        %{
          "apiGroups" => [""],
          "resources" => ["pods"],
          "verbs" => ["delete", "get", "list", "patch", "update", "watch"]
        },
        %{"apiGroups" => [""], "resources" => ["pods/exec"], "verbs" => ["create"]},
        %{
          "apiGroups" => [""],
          "resources" => ["services"],
          "verbs" => ["create", "delete", "get", "patch", "update"]
        },
        %{
          "apiGroups" => ["apps"],
          "resources" => ["statefulsets", "deployments"],
          "verbs" => ["create", "delete", "get", "list", "patch"]
        },
        %{
          "apiGroups" => ["batch"],
          "resources" => ["cronjobs"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get"]},
        %{
          "apiGroups" => ["policy"],
          "resources" => ["poddisruptionbudgets"],
          "verbs" => ["create", "delete", "get"]
        },
        %{"apiGroups" => [""], "resources" => ["serviceaccounts"], "verbs" => ["get", "create"]},
        %{
          "apiGroups" => ["rbac.authorization.k8s.io"],
          "resources" => ["rolebindings"],
          "verbs" => ["get", "create"]
        }
      ]
    }
  end

  def cluster_role_binding_0(config) do
    namespace = DatabaseSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-postgres-operator",
        "labels" => %{
          "app.kubernetes.io/name" => "postgres-operator",
          "app.kubernetes.io/instance" => "battery",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-postgres-operator"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-postgres-operator",
          "namespace" => namespace
        }
      ]
    }
  end

  def service_0(config) do
    namespace = DatabaseSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/name" => "postgres-operator",
          "app.kubernetes.io/instance" => "battery",
          "battery-managed" => "True"
        },
        "namespace" => namespace,
        "name" => "battery-postgres-operator"
      },
      "spec" => %{
        "type" => "ClusterIP",
        "ports" => [%{"port" => 8080, "protocol" => "TCP", "targetPort" => 8080}],
        "selector" => %{
          "app.kubernetes.io/instance" => "battery",
          "app.kubernetes.io/name" => "postgres-operator"
        }
      }
    }
  end

  def deployment_0(config) do
    namespace = DatabaseSettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/name" => "postgres-operator",
          "app.kubernetes.io/instance" => "battery",
          "battery-managed" => "True"
        },
        "namespace" => namespace,
        "name" => "battery-postgres-operator"
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/name" => "postgres-operator",
            "app.kubernetes.io/instance" => "battery"
          }
        },
        "template" => %{
          "metadata" => %{
            "annotations" => %{},
            "labels" => %{
              "app.kubernetes.io/name" => "postgres-operator",
              "app.kubernetes.io/instance" => "battery",
              "battery-managed" => "True"
            }
          },
          "spec" => %{
            "serviceAccountName" => "battery-postgres-operator",
            "containers" => [
              %{
                "name" => "postgres-operator",
                "image" => "registry.opensource.zalan.do/acid/postgres-operator:v1.6.2",
                "imagePullPolicy" => "IfNotPresent",
                "env" => [
                  %{
                    "name" => "POSTGRES_OPERATOR_CONFIGURATION_OBJECT",
                    "value" => "battery-postgres-operator"
                  }
                ],
                "resources" => %{
                  "limits" => %{"cpu" => "500m", "memory" => "500Mi"},
                  "requests" => %{"cpu" => "100m", "memory" => "250Mi"}
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "readOnlyRootFilesystem" => true,
                  "runAsNonRoot" => true,
                  "runAsUser" => 1000
                }
              }
            ],
            "affinity" => %{},
            "nodeSelector" => %{},
            "tolerations" => []
          }
        }
      }
    }
  end

  def pod_service_role_binding(config) do
    # This whole thing should be un-needed. However it is.
    #
    # The operator creates the service account in each namespace.  (reasonable)
    # We create the single ClusterRole.
    # The operator then creates a RoleBinding pointing to a subject of
    # the service account in the default namespace rather than the correct one.
    namespace = DatabaseSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "postgres-pod"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "postgres-pod"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "postgres-pod",
          "namespace" => namespace
        }
      ]
    }
  end

  def operator_configuration_0(config) do
    namespace = DatabaseSettings.namespace(config)

    # Zalando's postgres operator creates the

    %{
      "apiVersion" => "acid.zalan.do/v1",
      "kind" => "OperatorConfiguration",
      "metadata" => %{
        "name" => "battery-postgres-operator",
        "namespace" => namespace,
        "labels" => %{
          "app.kubernetes.io/name" => "postgres-operator",
          "app.kubernetes.io/instance" => "battery",
          "battery-managed" => "True"
        }
      },
      "configuration" => %{
        "enable_crd_validation" => true,
        "workers" => 8,
        "major_version_upgrade" => %{
          "major_version_upgrade_mode" => "manual",
          "minimal_major_version" => "9.5",
          "target_major_version" => "13"
        },
        "kubernetes" => %{
          "oauth_token_secret_name" => "battery-postgres-operator",
          "cluster_name_label" => "battery-cluster-name",
          "watched_namespace" => "battery-db"
        },
        "debug" => %{"debug_logging" => true, "enable_database_access" => true}
      }
    }
  end

  def materialize(config) do
    %{
      "/0/service_account_0" => service_account_0(config),
      "/1/cluster_role_0" => cluster_role_0(config),
      "/2/cluster_role_1" => cluster_role_1(config),
      "/3/cluster_role_binding_0" => cluster_role_binding_0(config),
      "/3/cluster_role_binding_1" => pod_service_role_binding(config),
      "/4/service_0" => service_0(config),
      "/5/deployment_0" => deployment_0(config),
      "/6/operator_configuration_0" => operator_configuration_0(config)
    }
  end
end
