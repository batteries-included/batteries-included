defmodule KubeRawResources.PostgresOperator do
  @moduledoc false
  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeRawResources.DatabaseSettings

  @app_name "postgres-operator"
  @postgres_crd_path "priv/manifests/postgres/postgres_operator-crds.yaml"

  def service_account(_config, namespace) do
    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-postgres-operator",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => @app_name,
          "app.kubernetes.io/instance" => "battery",
          "battery/managed" => "true"
        }
      }
    }
  end

  def cluster_role_0(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-postgres-pod",
        "labels" => %{
          "battery/app" => @app_name,
          "app.kubernetes.io/instance" => "battery",
          "battery/managed" => "true"
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
          "battery/app" => @app_name,
          "app.kubernetes.io/instance" => "battery",
          "battery/managed" => "true"
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

  def cluster_role_binding(_config, namespace) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-postgres-operator-#{namespace}",
        "labels" => %{
          "battery/app" => @app_name,
          "app.kubernetes.io/instance" => "battery",
          "battery/managed" => "true"
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

  def service(_config, namespace) do
    spec = %{
      "type" => "ClusterIP",
      "ports" => [%{"port" => 8080, "protocol" => "TCP", "targetPort" => 8080}],
      "selector" => %{
        "app.kubernetes.io/instance" => "battery",
        "battery/app" => @app_name
      }
    }

    B.build_resource(:service)
    |> B.name("postgres-operator")
    |> B.namespace(namespace)
    |> Map.put("spec", spec)
  end

  def deployment(config, namespace) do
    operator_image = DatabaseSettings.pg_operator_image(config)
    operator_version = DatabaseSettings.pg_operator_version(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "app.kubernetes.io/instance" => "battery",
          "battery/managed" => "true"
        },
        "namespace" => namespace,
        "name" => "postgres-operator"
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "app.kubernetes.io/instance" => "battery"
          }
        },
        "template" => %{
          "metadata" => %{
            "annotations" => %{},
            "labels" => %{
              "battery/app" => @app_name,
              "app.kubernetes.io/instance" => "battery",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "serviceAccountName" => "battery-postgres-operator",
            "containers" => [
              %{
                "name" => "postgres-operator",
                "image" => "#{operator_image}:#{operator_version}",
                "imagePullPolicy" => "IfNotPresent",
                "env" => [
                  %{
                    "name" => "POSTGRES_OPERATOR_CONFIGURATION_OBJECT",
                    "value" => "postgres-operator"
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

  def pod_service_role_binding(_config, namespace) do
    # This whole thing should be un-needed. However it is.
    #
    # The operator creates the service account in each namespace.  (reasonable)
    # We create the single ClusterRole.
    # The operator then creates a RoleBinding pointing to a subject of
    # the service account in the default namespace rather than the correct one.

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-postgres-pod-#{namespace}")
    |> B.app_labels(@app_name)
    |> Map.put("roleRef", %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "ClusterRole",
      "name" => "battery-postgres-pod"
    })
    |> Map.put("subjects", [
      %{
        "kind" => "ServiceAccount",
        "name" => "battery-postgres-pod",
        "namespace" => namespace
      }
    ])
  end

  def operator_configuration(config, namespace, include_dev_infrausers \\ false) do
    # Zalando's postgres operator creates the

    %{
      "apiVersion" => "acid.zalan.do/v1",
      "kind" => "OperatorConfiguration",
      "metadata" => %{
        "name" => "postgres-operator",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => @app_name,
          "app.kubernetes.io/instance" => "battery",
          "battery/managed" => "true"
        }
      },
      "configuration" => %{
        "enable_crd_validation" => true,
        "workers" => 4,
        "major_version_upgrade" => %{
          "major_version_upgrade_mode" => "manual",
          "minimal_major_version" => "9.5",
          "target_major_version" => "13"
        },
        "kubernetes" => operator_configuration_kubernets(config, include_dev_infrausers),
        "debug" => %{"debug_logging" => true, "enable_database_access" => true}
      }
    }
  end

  defp operator_configuration_kubernets(config, false = _include_dev_infrausers) do
    label_name = DatabaseSettings.cluster_name_label(config)

    %{
      "oauth_token_secret_name" => "battery-postgres-operator",
      "pod_service_account_name" => "battery-postgres-pod",
      "cluster_name_label" => label_name
    }
  end

  defp operator_configuration_kubernets(config, true = _include_dev_infrausers),
    do:
      Map.put(
        operator_configuration_kubernets(config, false),
        "infrastructure_roles_secret_name",
        "postgres-infrauser-config"
      )

  defp include_dev_infrausers,
    do: Application.get_env(:kube_raw_resources, :include_dev_infrausers, false)

  defp infra_users(config, true = _include_dev_infrausers) do
    %{
      "/infra_configmap" => infra_configmap(config),
      "/infra_secret" => infra_secret(config)
    }
  end

  defp infra_users(_config, _include_dev_infrausers) do
    %{}
  end

  defp infra_configmap(config) do
    namespace = DatabaseSettings.namespace(config)

    B.build_resource(:config_map)
    |> B.app_labels("postgres-operator")
    |> B.namespace(namespace)
    |> B.name("postgres-infrauser-config")
    |> Map.put(
      "data",
      %{
        "batterydbuser" => Ymlr.Encoder.to_s!(%{user_flags: ["createdb", "superuser"]})
      }
    )
  end

  defp infra_secret(config) do
    namespace = DatabaseSettings.namespace(config)

    B.build_resource(:secret)
    |> B.app_labels("postgres-operator")
    |> B.namespace(namespace)
    |> B.name("postgres-infrauser-config")
    |> Map.put("data", %{
      "batterydbuser" => Base.encode64("not-real")
    })
  end

  defp postgres_crd_content, do: unquote(File.read!(@postgres_crd_path))

  defp postgres_crd do
    yaml(postgres_crd_content())
  end

  def materialize_internal(config) do
    namespace = DatabaseSettings.namespace(config)
    infrausers = include_dev_infrausers()

    %{}
    |> Map.merge(materialize_in_namespace(config, namespace))
    |> Map.merge(%{
      "/operator_crd_instance" => operator_configuration(config, namespace, infrausers)
    })
    |> Map.merge(infra_users(config, infrausers))
  end

  def materialize_public(config) do
    namespace = DatabaseSettings.public_namespace(config)

    %{}
    |> Map.merge(materialize_in_namespace(config, namespace))
    |> Map.merge(%{
      "/operator_crd_instance" => operator_configuration(config, namespace, false)
    })
  end

  def materialize_common(config) do
    %{
      "/crd" => postgres_crd(),
      "/cluster_role/0" => cluster_role_0(config),
      "/cluster_role/1" => cluster_role_1(config)
    }
  end

  def materialize_in_namespace(config, namespace) do
    %{
      "/service_account" => service_account(config, namespace),
      "/cluster_role_binding" => cluster_role_binding(config, namespace),
      "/pod_service_role_binding" => pod_service_role_binding(config, namespace),
      "/service" => service(config, namespace),
      "/deployment_0" => deployment(config, namespace)
    }
  end
end
