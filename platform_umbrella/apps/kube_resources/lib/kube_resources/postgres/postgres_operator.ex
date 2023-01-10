defmodule KubeResources.PostgresOperator do
  use CommonCore.IncludeResource,
    operatorconfigurations_acid_zalan_do:
      "priv/manifests/postgres-operator/operatorconfigurations_acid_zalan_do.yaml",
    postgresqls_acid_zalan_do: "priv/manifests/postgres-operator/postgresqls_acid_zalan_do.yaml",
    postgresteams_acid_zalan_do:
      "priv/manifests/postgres-operator/postgresteams_acid_zalan_do.yaml"

  use KubeExt.ResourceGenerator

  import CommonCore.Yaml
  import CommonCore.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.Secret

  @app_name "battery-postgres-operator"

  @service_account "battery-postgres-operator"
  @postgres_pod_service_account "battery-postgres-pod"
  @cluster_role "battery-postgres-operator-role"

  @infa_user_config "postgres-operator-infrauser-config"

  resource(:cluster_role_binding_postgres_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("postgres-operator")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref(@cluster_role))
    |> B.subject(B.build_service_account(@service_account, namespace))
  end

  resource(:cluster_role_postgres_operator) do
    rules = [
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
    ]

    B.build_resource(:cluster_role)
    |> B.name(@cluster_role)
    |> B.app_labels(@app_name)
    |> B.rules(rules)
  end

  resource(:service_account_postgres_pod_data, _battery, state) do
    namespace = data_namespace(state)

    B.build_resource(:service_account)
    |> B.name(@postgres_pod_service_account)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_account_postgres_pod_base, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> B.name(@postgres_pod_service_account)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:cluster_role_binding_postgres_pod, _battery, state) do
    data_namespace = data_namespace(state)
    base_namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name(@postgres_pod_service_account)
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref(@postgres_pod_service_account))
    |> B.subject(B.build_service_account(@postgres_pod_service_account, data_namespace))
    |> B.subject(B.build_service_account(@postgres_pod_service_account, base_namespace))
  end

  resource(:cluster_role_postgres_pod) do
    rules = [
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

    B.build_resource(:cluster_role)
    |> B.name(@postgres_pod_service_account)
    |> B.app_labels(@app_name)
    |> B.rules(rules)
  end

  resource(:service_account_postgres_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name(@service_account)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:deployment_postgres_operator, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name
          }
        }
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
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
                  }
                ],
                "image" => battery.config.image,
                "imagePullPolicy" => "IfNotPresent",
                "name" => "postgres-operator",
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
            "nodeSelector" => %{},
            "serviceAccountName" => @service_account,
            "tolerations" => []
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("postgres-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:postgresql_operator_config_main, battery, state) do
    namespace = core_namespace(state)

    configuration = %{
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
      "etcd_host" => "",
      "kubernetes" => %{
        "cluster_domain" => "cluster.local",
        "cluster_labels" => %{"application" => "spilo"},
        "cluster_name_label" => "cluster-name",
        "enable_cross_namespace_secret" => false,
        "enable_init_containers" => true,
        "enable_pod_antiaffinity" => false,
        "enable_pod_disruption_budget" => true,
        "enable_sidecars" => true,
        "inherited_labels" => ["battery/app", "app", "sidecar.istio.io/inject", "battery/owner"],
        "infrastructure_roles_secret_name" => @infa_user_config,
        "oauth_token_secret_name" => "postgres-operator",
        "pdb_name_format" => "postgres-{cluster}-pdb",
        "pod_antiaffinity_topology_key" => "kubernetes.io/hostname",
        "pod_management_policy" => "ordered_ready",
        "pod_role_label" => "spilo-role",
        "pod_service_account_name" => @postgres_pod_service_account,
        "pod_terminate_grace_period" => "5m",
        "secret_name_template" => "{username}.{cluster}.credentials.{tprkind}",
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
      "logging_rest_api" => %{
        "api_port" => 8080,
        "cluster_history_entries" => 1000,
        "ring_log_lines" => 100
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
      "major_version_upgrade" => %{
        "major_version_upgrade_mode" => "manual",
        "minimal_major_version" => "9.6",
        "target_major_version" => "14"
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
        "enable_admin_role_for_users" => false,
        "enable_postgres_team_crd" => false,
        "enable_postgres_team_crd_superusers" => false,
        "enable_team_member_deprecation" => false,
        "enable_team_superuser" => false,
        "enable_teams_api" => false,
        "pam_role_name" => "batteries_included",
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
      "workers" => 8
    }

    B.build_resource(:postgresql_operator_config)
    |> Map.put("configuration", configuration)
    |> B.name("postgres-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_postgres_operator, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"port" => 8080, "protocol" => "TCP", "targetPort" => 8080}])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("postgres-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:secret_postgres_infra_users, battery, state) do
    namespace = core_namespace(state)

    data = infra_users_password_map(battery, state)

    B.build_resource(:secret)
    |> B.app_labels(@app_name)
    |> B.namespace(namespace)
    |> B.name(@infa_user_config)
    |> B.data(data)
  end

  resource(:configmap_infra_users, battery, state) do
    namespace = core_namespace(state)

    data = infra_users_config_map(battery, state)

    B.build_resource(:config_map)
    |> B.app_labels(@app_name)
    |> B.namespace(namespace)
    |> B.name(@infa_user_config)
    |> B.data(data)
  end

  defp infra_users_password_map(battery, _state) do
    battery.config.infra_users
    |> Enum.map(fn u -> {u.username, u.generated_key} end)
    |> Secret.encode()
  end

  defp infra_users_config_map(battery, _state) do
    battery.config.infra_users
    |> Enum.map(fn u -> {u.username, Ymlr.Encoder.to_s!(%{user_flags: u.roles})} end)
    |> Map.new()
  end

  resource(:crd_operatorconfigurations_acid_zalan_do) do
    yaml(get_resource(:operatorconfigurations_acid_zalan_do))
  end

  resource(:crd_postgresqls_acid_zalan_do) do
    yaml(get_resource(:postgresqls_acid_zalan_do))
  end

  resource(:crd_postgresteams_acid_zalan_do) do
    yaml(get_resource(:postgresteams_acid_zalan_do))
  end
end
