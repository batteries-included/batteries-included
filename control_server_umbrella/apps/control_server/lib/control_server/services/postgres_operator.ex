defmodule ControlServer.Services.PostgresOperator do
  @moduledoc """
  Module for installing and dealing with the postgres operator.
  """
  alias ControlServer.Postgres.Cluster
  alias ControlServer.Settings.DatabaseSettings

  def config(config) do
    namespace = DatabaseSettings.namespace(config)
    name = DatabaseSettings.pg_operator_name(config)

    pod_account = DatabaseSettings.pg_operator_pod_account_name(config)

    %{
      "apiVersion" => "acid.zalan.do/v1",
      "kind" => "OperatorConfiguration",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      },
      "configuration" => %{
        "repair_period" => "5m",
        "workers" => 4,
        "users" => %{
          "replication_username" => "standby",
          "super_username" => "postgres"
        },
        "kubernetes" => %{
          "pod_service_account_name" => pod_account,
          "cluster_labels" => %{
            "application" => "spilo",
            "battery" => "true"
          },
          "enable_sidecars" => true
        },
        "postgres_pod_resources" => %{
          "default_cpu_limit" => "1",
          "default_cpu_request" => "100m",
          "default_memory_limit" => "500Mi",
          "default_memory_request" => "100Mi"
        },
        "timeouts" => %{
          "pod_label_wait_timeout" => "10m",
          "pod_deletion_wait_timeout" => "10m",
          "ready_wait_interval" => "4s",
          "ready_wait_timeout" => "30s",
          "resource_check_interval" => "3s",
          "resource_check_timeout" => "10m"
        },
        "load_balancer" => %{
          "enable_master_load_balancer" => false,
          "enable_replica_load_balancer" => false
        },
        "debug" => %{
          "debug_logging" => true,
          "enable_database_access" => true
        }
      }
    }
  end

  def deployment(config) do
    namespace = DatabaseSettings.namespace(config)
    name = DatabaseSettings.pg_operator_name(config)
    image = DatabaseSettings.pg_operator_image(config)
    version = DatabaseSettings.pg_operator_version(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace,
        "labels" => %{
          "application" => "postgres-operator"
        }
      },
      "spec" => %{
        "replicas" => 1,
        "strategy" => %{
          "type" => "Recreate"
        },
        "selector" => %{
          "matchLabels" => %{
            "name" => name
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "name" => name
            }
          },
          "spec" => %{
            "serviceAccountName" => name,
            "containers" => [
              %{
                "name" => "postgres-operator",
                "image" => "#{image}:#{version}",
                "imagePullPolicy" => "IfNotPresent",
                "resources" => %{
                  "requests" => %{
                    "cpu" => "100m",
                    "memory" => "250Mi"
                  },
                  "limits" => %{
                    "cpu" => "500m",
                    "memory" => "500Mi"
                  }
                },
                "securityContext" => %{
                  "runAsUser" => 1000,
                  "runAsNonRoot" => true,
                  "readOnlyRootFilesystem" => true,
                  "allowPrivilegeEscalation" => false
                },
                "env" => [
                  %{
                    "name" => "POSTGRES_OPERATOR_CONFIGURATION_OBJECT",
                    "value" => name
                  }
                ]
              }
            ]
          }
        }
      }
    }
  end

  def service_account(config) do
    namespace = DatabaseSettings.namespace(config)
    name = DatabaseSettings.pg_operator_name(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      }
    }
  end

  def pod_service_account(config) do
    namespace = DatabaseSettings.namespace(config)
    name = DatabaseSettings.pg_operator_pod_account_name(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace
      }
    }
  end

  def pod_cluster_role(config) do
    name = DatabaseSettings.pg_operator_pod_account_name(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => name
      },
      "rules" => [
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "endpoints"
          ],
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
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "pods"
          ],
          "verbs" => [
            "get",
            "list",
            "patch",
            "update",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "services"
          ],
          "verbs" => [
            "create"
          ]
        }
      ]
    }
  end

  def cluster_role(config) do
    name = DatabaseSettings.pg_operator_name(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => name
      },
      "rules" => [
        %{
          "apiGroups" => [
            "acid.zalan.do"
          ],
          "resources" => [
            "postgresqls",
            "postgresqls/status",
            "operatorconfigurations"
          ],
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
          "apiGroups" => [
            "acid.zalan.do"
          ],
          "resources" => [
            "postgresteams"
          ],
          "verbs" => [
            "get",
            "list",
            "watch"
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
            "create",
            "get",
            "patch",
            "update"
          ]
        },
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "configmaps"
          ],
          "verbs" => [
            "get"
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
            "get",
            "list",
            "patch",
            "update",
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
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "secrets"
          ],
          "verbs" => [
            "create",
            "delete",
            "get",
            "update"
          ]
        },
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "nodes"
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
            "persistentvolumeclaims"
          ],
          "verbs" => [
            "delete",
            "get",
            "list",
            "patch",
            "update"
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
            "update"
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
            "delete",
            "get",
            "list",
            "patch",
            "update",
            "watch"
          ]
        },
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "pods/exec"
          ],
          "verbs" => [
            "create"
          ]
        },
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "services"
          ],
          "verbs" => [
            "create",
            "delete",
            "get",
            "patch",
            "update"
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
            "create",
            "delete",
            "get",
            "list",
            "patch"
          ]
        },
        %{
          "apiGroups" => [
            "batch"
          ],
          "resources" => [
            "cronjobs"
          ],
          "verbs" => [
            "create",
            "delete",
            "get",
            "list",
            "patch",
            "update"
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
            "get"
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
            "create",
            "delete",
            "get"
          ]
        },
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "serviceaccounts"
          ],
          "verbs" => [
            "get",
            "create"
          ]
        },
        %{
          "apiGroups" => [
            "rbac.authorization.k8s.io"
          ],
          "resources" => [
            "rolebindings"
          ],
          "verbs" => [
            "get",
            "create"
          ]
        }
      ]
    }
  end

  def cluster_role_bind(config) do
    namespace = DatabaseSettings.namespace(config)
    name = DatabaseSettings.pg_operator_name(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => name
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => name
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => name,
          "namespace" => namespace
        }
      ]
    }
  end

  def pod_cluster_role_bind(config) do
    namespace = DatabaseSettings.namespace(config)
    name = DatabaseSettings.pg_operator_pod_account_name(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => name
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => name
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => name,
          "namespace" => namespace
        }
      ]
    }
  end

  def postgres(%Cluster{} = cluster, config) do
    namespace = DatabaseSettings.namespace(config)

    %{
      "apiVersion" => "acid.zalan.do/v1",
      "kind" => "postgresql",
      "metadata" => %{
        "name" => "default-" <> cluster.name,
        "namespace" => namespace
      },
      "spec" => %{
        "teamId" => "default",
        "numberOfInstances" => cluster.num_instances,
        "postgresql" => %{
          "version" => cluster.postgres_version
        },
        "volume" => %{
          "size" => cluster.size
        }
      }
    }
  end
end
