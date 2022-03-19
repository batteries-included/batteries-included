defmodule KubeRawResources.Database do
  import KubeRawResources.RawCluster

  alias KubeExt.Builder, as: B

  alias KubeRawResources.DatabaseSettings
  alias KubeRawResources.PostgresOperator

  @exporter_port 9187
  @exporter_port_name "exporter"

  @pam_group_name "batterpamusers"

  @app "postgres-operator"

  @pg_hba [
    ["local", "all", "all", "trust"],
    ["hostssl", "all", "+#{@pam_group_name}", "127.0.0.1/32", "pam"],
    ["host", "all", "all", "127.0.0.1/32", "md5"],
    ["hostssl", "all", "+#{@pam_group_name}", "::1/128", "pam"],
    ["host", "all", "all", "::1/128", "md5"],
    ["hostssl", "replication", "standby", "all", "md5"],
    ["hostssl", "replication", "standby", "all", "scram-sha-256"],

    # This line is added to allow postgres_exporter to attach since it can't use ssl yet.
    # Certs aren't correct.
    ["hostnossl", "all", "postgres", "0.0.0.0/0", "md5"],
    ["hostssl", "all", "postgres", "0.0.0.0/0", "md5"],
    ["hostssl", "all", "postgres", "0.0.0.0/0", "scram-sha-256"],

    ["hostssl", "all", "batterydbuser", "0.0.0.0/0", "md5"],
    ["hostssl", "all", "batterydbuser", "0.0.0.0/0", "scram-sha-256"],

    ["hostnossl", "all", "all", "all", "reject"],
    ["hostssl", "all", "all", "all", "md5"],
    ["hostssl", "all", "all", "all", "scram-sha-256"]
  ]

  def postgres(%{} = cluster, config) do
    namespace = namespace(cluster, config)

    spec = postgres_spec(cluster)

    B.build_resource(:postgresql)
    |> B.namespace(namespace)
    |> B.name(full_name(cluster))
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  defp postgres_spec(cluster) do
    %{
      "teamId" => team_name(cluster),
      "numberOfInstances" => num_instances(cluster),
      "postgresql" => %{
        "version" => postgres_version(cluster)
      },
      "patroni" => %{"pg_hba" => pg_hba()},
      "volume" => %{
        "size" => storage_size(cluster)
      },
      "pam_role_name" => "batteryusers",
      "users" => users(cluster),
      "databases" => databases(cluster),
      "sidecars" => [
        exporter_sidecar(cluster)
      ]
    }
  end

  def metrics_service(%{} = cluster, config, role) do
    namespace = namespace(cluster, config)
    label_name = DatabaseSettings.cluster_name_label(config)
    cluster_name = full_name(cluster)

    selector = cluster |> cluster_label_selector(config, role) |> Map.put("application", "spilo")

    spec =
      %{}
      |> Map.put("selector", selector)
      |> B.ports([
        %{
          "name" => @exporter_port_name,
          "port" => @exporter_port,
          "targetPort" => @exporter_port_name
        }
      ])

    service_name = "#{cluster_name}-#{role}-mon"

    B.build_resource(:service)
    |> B.app_labels(@app)
    |> B.label(label_name, cluster_name)
    |> B.label("spilo-role", role)
    |> B.namespace(namespace)
    |> B.name(service_name)
    |> B.spec(spec)
  end

  defp cluster_label_selector(%{} = cluster, config, role) do
    cluster_name = full_name(cluster)
    label_name = DatabaseSettings.cluster_name_label(config)

    %{
      label_name => cluster_name,
      "spilo-role" => role
    }
  end

  def service_monitor(%{} = cluster, config, role) do
    namespace = namespace(cluster, config)
    cluster_name = full_name(cluster)
    label_name = DatabaseSettings.cluster_name_label(config)

    monitor_name = "#{cluster_name}-#{role}"

    spec =
      %{}
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("selector", %{"matchLabels" => cluster_label_selector(cluster, config, role)})
      |> Map.put("endpoints", [
        %{
          "port" => @exporter_port_name,
          "interval" => "30s",
          "scheme" => "http",
          "scrapeTimeout" => "10s"
        }
      ])

    B.build_resource(:service_monitor)
    |> B.app_labels("postgres-operator")
    |> B.label(label_name, cluster_name)
    |> B.label("spilo-role", role)
    |> B.namespace(namespace)
    |> B.name(monitor_name)
    |> B.spec(spec)
  end

  defp exporter_sidecar(cluster) do
    cluster_name = full_name(cluster)

    %{
      "name" => "metrics-exporter",
      "image" => "quay.io/prometheuscommunity/postgres-exporter",
      "ports" => [
        %{
          "name" => @exporter_port_name,
          "containerPort" => @exporter_port,
          "protocol" => "TCP"
        }
      ],
      "resources" => %{
        "limits" => %{"cpu" => "200m", "memory" => "256M"},
        "requests" => %{"cpu" => "100m", "memory" => "256M"}
      },
      "env" => [
        %{"name" => "DATA_SOURCE_URI", "value" => "#{cluster_name}?sslmode=disable"},
        %{
          "name" => "DATA_SOURCE_USER",
          "valueFrom" => %{
            "secretKeyRef" => %{
              "name" => "postgres.#{cluster_name}.credentials.postgresql.acid.zalan.do",
              "key" => "username"
            }
          }
        },
        %{
          "name" => "DATA_SOURCE_PASS",
          "valueFrom" => %{
            "secretKeyRef" => %{
              "name" => "postgres.#{cluster_name}.credentials.postgresql.acid.zalan.do",
              "key" => "password"
            }
          }
        },
        %{
          "name" => "PG_EXPORTER_AUTO_DISCOVER_DATABASES",
          "value" => "true"
        }
      ]
    }
  end

  defp pg_hba do
    Enum.map(@pg_hba, fn spec -> Enum.join(spec, "\t") end)
  end

  defp bootstrap_clusters(config) do
    config
    |> DatabaseSettings.bootstrap_clusters()
    |> Enum.map(fn cluster -> postgres(cluster, config) end)
  end

  def materialize_common(%{} = config) do
    PostgresOperator.materialize_common(config)
  end

  def materialize(%{} = config) do
    %{}
    |> Map.merge(PostgresOperator.materialize_internal(config))
    |> Map.merge(%{"/9/boostrap_clusters" => bootstrap_clusters(config)})
  end
end
