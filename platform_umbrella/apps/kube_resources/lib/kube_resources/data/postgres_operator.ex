defmodule KubeResources.PostgresOperator do
  use KubeExt.IncludeResource,
    operatorconfigurations_acid_zalan_do:
      "priv/manifests/postgres-operator/operatorconfigurations_acid_zalan_do.yaml",
    postgresqls_acid_zalan_do: "priv/manifests/postgres-operator/postgresqls_acid_zalan_do.yaml",
    postgresteams_acid_zalan_do:
      "priv/manifests/postgres-operator/postgresteams_acid_zalan_do.yaml"

  import KubeExt.Yaml
  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeResources.PostgresPod

  @app_name "postgres-operator"
  @operator_cluster_role "battery-postgres-operator"

  def materialize(battery, state) do
    %{}
    |> Map.put("/cluster_role/postgres_operator", cluster_role_postgres_operator(battery, state))
    |> Map.put(
      "/cluster_role_binding/postgres_operator",
      cluster_role_binding_postgres_operator(battery, state)
    )
    |> Map.put(
      "/crd/operatorconfigurations_acid_zalan_do",
      crd_operatorconfigurations_acid_zalan_do(battery, state)
    )
    |> Map.put("/crd/postgresqls_acid_zalan_do", crd_postgresqls_acid_zalan_do(battery, state))
    |> Map.put(
      "/crd/postgresteams_acid_zalan_do",
      crd_postgresteams_acid_zalan_do(battery, state)
    )
    |> Map.put("/deployment/postgres_operator", deployment_postgres_operator(battery, state))
    |> Map.put(
      "/postgresql_operator_config/main",
      postgresql_operator_config_main(battery, state)
    )
    |> Map.put("/service/postgres_operator", service_postgres_operator(battery, state))
    |> Map.put(
      "/service_account/postgres_operator",
      service_account_postgres_operator(battery, state)
    )
    |> Map.merge(PostgresPod.common(battery, state))
    |> Map.merge(infra_users(battery, state, should_include_dev_infrausers()))
  end

  def cluster_role_binding_postgres_operator(_battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-postgres-operator")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref(@operator_cluster_role))
    |> B.subject(B.build_service_account("postgres-operator", namespace))
  end

  def cluster_role_postgres_operator(_battery, _state) do
    B.build_resource(:cluster_role)
    |> B.name(@operator_cluster_role)
    |> B.app_labels(@app_name)
    |> B.rules([
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
        "verbs" => ["get"]
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
    ])
  end

  def crd_operatorconfigurations_acid_zalan_do(_battery, _state) do
    yaml(get_resource(:operatorconfigurations_acid_zalan_do))
  end

  def crd_postgresqls_acid_zalan_do(_battery, _state) do
    yaml(get_resource(:postgresqls_acid_zalan_do))
  end

  def crd_postgresteams_acid_zalan_do(_battery, _state) do
    yaml(get_resource(:postgresteams_acid_zalan_do))
  end

  def deployment_postgres_operator(battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:deployment)
    |> B.name("postgres-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "battery/component" => "postgres-operator"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app_name,
            "battery/component" => "postgres-operator",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "affinity" => %{},
          "containers" => [
            %{
              "env" => [
                %{
                  "name" => "POSTGRES_OPERATOR_CONFIGURATION_OBJECT",
                  "value" => "postgres-operator"
                },
                %{
                  "name" => "ENABLE_JSON_LOGGING",
                  "value" => to_string(battery.config.json_logging_enabled)
                }
              ],
              "image" => battery.config.image,
              "imagePullPolicy" => "IfNotPresent",
              "name" => "postgres-operator",
              "resources" => %{
                "limits" => %{"memory" => "500Mi"},
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
          "nodeSelector" => %{},
          "serviceAccountName" => "postgres-operator",
          "tolerations" => []
        }
      }
    })
  end

  defp should_include_dev_infrausers,
    do: Application.get_env(:kube_resources, :include_dev_infrausers, false)

  defp maybe_add_infrausers(resource, true = _include_dev_infrausers) do
    put_in(
      resource,
      ["kubernetes", "infrastructure_roles_secret_name"],
      "postgres-infrauser-config"
    )
  end

  defp maybe_add_infrausers(resource, _include_dev_infrausers), do: resource

  defp infra_users(battery, state, true = _include_dev_infrausers) do
    %{
      "/infra_configmap" => infra_configmap(battery, state),
      "/infra_secret" => infra_secret(battery, state)
    }
  end

  defp infra_users(_battery, _state, _include_dev_infrausers), do: %{}

  defp infra_configmap(_battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:config_map)
    |> B.app_labels(@app_name)
    |> B.namespace(namespace)
    |> B.name("postgres-infrauser-config")
    |> B.data(%{
      "batterydbuser" => Ymlr.Encoder.to_s!(%{user_flags: ["createdb", "superuser"]})
    })
  end

  defp infra_secret(_battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:secret)
    |> B.app_labels(@app_name)
    |> B.namespace(namespace)
    |> B.name("postgres-infrauser-config")
    |> B.data(%{
      "batterydbuser" => Base.encode64("not-real")
    })
  end

  def postgresql_operator_config_main(battery, state) do
    namespace = core_namespace(state)

    config = %{
      "aws_or_gcp" => %{"aws_region" => "eu-central-1", "enable_ebs_gp3_migration" => false},
      "connection_pooler" => %{
        "connection_pooler_default_cpu_limit" => "1",
        "connection_pooler_default_cpu_request" => "500m",
        "connection_pooler_default_memory_limit" => "100Mi",
        "connection_pooler_default_memory_request" => "100Mi",
        "connection_pooler_image" => battery.config.bouncer_image,
        "connection_pooler_max_db_connections" => 60,
        "connection_pooler_mode" => "transaction",
        "connection_pooler_number_of_instances" => 2,
        "connection_pooler_schema" => "pooler",
        "connection_pooler_user" => "pooler"
      },
      "crd_categories" => ["all"],
      "debug" => %{"debug_logging" => true, "enable_database_access" => true},
      "docker_image" => battery.config.spilo_image,
      "enable_crd_registration" => false,
      "enable_lazy_spilo_upgrade" => false,
      "enable_pgversion_env_var" => true,
      "enable_shm_volume" => true,
      "enable_spilo_wal_path_compat" => false,
      "kubernetes" => %{
        "cluster_domain" => "cluster.local",
        "cluster_labels" => %{"application" => "spilo"},
        "cluster_name_label" => "cluster-name",
        "enable_cross_namespace_secret" => false,
        "enable_init_containers" => true,
        "enable_pod_antiaffinity" => false,
        "enable_pod_disruption_budget" => true,
        "enable_sidecars" => true,
        "oauth_token_secret_name" => "postgres-operator",
        "pdb_name_format" => "postgres-{cluster}-pdb",
        "pod_antiaffinity_topology_key" => "kubernetes.io/hostname",
        "pod_management_policy" => "ordered_ready",
        "pod_role_label" => "spilo-role",
        "pod_service_account_name" => PostgresPod.service_account_name(),
        "inherited_labels" => ["sidecar.istio.io/inject", "battery/app", "battery/owner"],
        "pod_terminate_grace_period" => "5m",
        "secret_name_template" => "{username}.{cluster}.credentials.{tprkind}.{tprgroup}",
        "spilo_allow_privilege_escalation" => true,
        "spilo_privileged" => false,
        "storage_resize_mode" => "pvc",
        "watched_namespace" => "*"
      },
      "load_balancer" => %{
        "db_hosted_zone" => "db.example.com",
        "enable_master_load_balancer" => false,
        "enable_master_pooler_load_balancer" => false,
        "enable_replica_load_balancer" => false,
        "enable_replica_pooler_load_balancer" => false,
        "external_traffic_policy" => "Cluster",
        "master_dns_name_format" => "{cluster}.{team}.{hostedzone}",
        "replica_dns_name_format" => "{cluster}-repl.{team}.{hostedzone}"
      },
      "logical_backup" => %{
        "logical_backup_docker_image" => battery.config.logical_backup_image,
        "logical_backup_job_prefix" => "logical-backup-",
        "logical_backup_provider" => "s3",
        "logical_backup_s3_access_key_id" => "",
        "logical_backup_s3_bucket" => "my-bucket-url",
        "logical_backup_s3_endpoint" => "",
        "logical_backup_s3_region" => "",
        "logical_backup_s3_retention_time" => "",
        "logical_backup_s3_secret_access_key" => "",
        "logical_backup_s3_sse" => "AES256",
        "logical_backup_schedule" => "30 00 * * *"
      },
      "max_instances" => -1,
      "min_instances" => -1,
      "postgres_pod_resources" => %{
        "default_cpu_limit" => "1",
        "default_cpu_request" => "100m",
        "default_memory_limit" => "500Mi",
        "default_memory_request" => "100Mi",
        "min_cpu_limit" => "250m",
        "min_memory_limit" => "250Mi"
      },
      "repair_period" => "5m",
      "resync_period" => "30m",
      "teams_api" => %{
        "enable_admin_role_for_users" => true,
        "enable_postgres_team_crd" => false,
        "enable_postgres_team_crd_superusers" => false,
        "enable_team_member_deprecation" => false,
        "enable_team_superuser" => false,
        "enable_teams_api" => false,
        "pam_role_name" => "batteryincl",
        "postgres_superuser_teams" => ["postgres_superusers"],
        "protected_role_names" => ["admin", "cron_admin"],
        "role_deletion_suffix" => "_deleted",
        "team_admin_role" => "admin",
        "team_api_role_configuration" => %{"log_statement" => "all"}
      },
      "timeouts" => %{
        "patroni_api_check_interval" => "1s",
        "patroni_api_check_timeout" => "5s",
        "pod_deletion_wait_timeout" => "10m",
        "pod_label_wait_timeout" => "10m",
        "ready_wait_interval" => "3s",
        "ready_wait_timeout" => "30s",
        "resource_check_interval" => "3s",
        "resource_check_timeout" => "10m"
      },
      "users" => %{
        "enable_password_rotation" => false,
        "password_rotation_interval" => 90,
        "password_rotation_user_retention" => 180,
        "replication_username" => "standby",
        "super_username" => "postgres"
      },
      "workers" => 6
    }

    B.build_resource(:postgresql_operator_config)
    |> Map.put("configuration", maybe_add_infrausers(config, should_include_dev_infrausers()))
    |> B.name("postgres-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def service_account_postgres_operator(_battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("postgres-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def service_postgres_operator(_battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service)
    |> B.name("postgres-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "ports" => [%{"port" => 8080, "protocol" => "TCP", "targetPort" => 8080}],
      "selector" => %{
        "battery/app" => "postgres-operator",
        "battery/component" => "postgres-operator"
      },
      "type" => "ClusterIP"
    })
  end
end
