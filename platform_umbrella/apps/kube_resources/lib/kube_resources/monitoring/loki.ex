defmodule KubeResources.Loki do
  use KubeExt.ResourceGenerator, app_name: "loki"

  import CommonCore.SystemState.Namespaces
  import CommonCore.Yaml

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F

  resource(:config_map_main, battery, state) do
    namespace = core_namespace(state)
    contents = battery |> config_contents(state) |> to_yaml()
    data = %{"config.yaml" => contents}

    B.build_resource(:config_map)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_account_main, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> Map.put("automountServiceAccountToken", true)
    |> B.namespace(namespace)
    |> B.name("loki")
  end

  resource(:service_headless, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{
          "name" => "http-metrics",
          "port" => 3100,
          "protocol" => "TCP",
          "targetPort" => "http-metrics"
        }
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("loki-headless")
    |> B.namespace(namespace)
    |> B.label("prometheus.io/service-monitor", "false")
    |> B.label("variant", "headless")
    |> B.spec(spec)
  end

  resource(:service_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{
          "name" => "http-metrics",
          "port" => 3100,
          "protocol" => "TCP",
          "targetPort" => "http-metrics"
        },
        %{"name" => "grpc", "port" => 9095, "protocol" => "TCP", "targetPort" => "grpc"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.component_label("main")
    |> B.spec(spec)
  end

  resource(:service_memberlist, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "tcp", "port" => 7946, "protocol" => "TCP", "targetPort" => "http-memberlist"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    B.build_resource(:service)
    |> B.name("loki-memberlist")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:stateful_set_main, battery, state) do
    namespace = core_namespace(state)

    template = %{
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "affinity" => %{
          "podAntiAffinity" => %{
            "requiredDuringSchedulingIgnoredDuringExecution" => [
              %{
                "labelSelector" => %{
                  "matchLabels" => %{"battery/app" => @app_name}
                },
                "topologyKey" => "kubernetes.io/hostname"
              }
            ]
          }
        },
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "args" => ["-config.file=/etc/loki/config/config.yaml", "-target=all"],
            "image" => battery.config.image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "single-binary",
            "ports" => [
              %{"containerPort" => 3100, "name" => "http-metrics", "protocol" => "TCP"},
              %{"containerPort" => 9095, "name" => "grpc", "protocol" => "TCP"},
              %{"containerPort" => 7946, "name" => "http-memberlist", "protocol" => "TCP"}
            ],
            "readinessProbe" => %{
              "httpGet" => %{"path" => "/ready", "port" => "http-metrics"},
              "initialDelaySeconds" => 30,
              "timeoutSeconds" => 1
            },
            "resources" => %{},
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "readOnlyRootFilesystem" => true
            },
            "volumeMounts" => [
              %{"mountPath" => "/tmp", "name" => "tmp"},
              %{"mountPath" => "/etc/loki/config", "name" => "config"},
              %{"mountPath" => "/var/loki", "name" => "storage"}
            ]
          }
        ],
        "securityContext" => %{
          "fsGroup" => 10_001,
          "runAsGroup" => 10_001,
          "runAsNonRoot" => true,
          "runAsUser" => 10_001
        },
        "serviceAccountName" => "loki",
        "terminationGracePeriodSeconds" => 30,
        "volumes" => [
          %{"emptyDir" => %{}, "name" => "tmp"},
          %{"configMap" => %{"name" => "loki"}, "name" => "config"}
        ]
      }
    }

    spec =
      %{}
      |> Map.put("podManagementPolicy", "Parallel")
      |> Map.put("replicas", battery.config.replicas)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )
      |> Map.put("serviceName", "loki-headless")
      |> Map.put("template", template)
      |> Map.put("updateStrategy", %{"rollingUpdate" => %{"partition" => 0}})
      |> Map.put("volumeClaimTemplates", [
        %{
          "metadata" => %{"name" => "storage"},
          "spec" => %{
            "accessModes" => ["ReadWriteOnce"],
            "resources" => %{"requests" => %{"storage" => "10Gi"}}
          }
        }
      ])

    B.build_resource(:stateful_set)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:monitoring_service_monitor_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "port" => "http-metrics",
          "scheme" => "http",
          "path" => "/metrics"
          # "relabelings" => [%{"replacement" => @app_name, "targetLabel" => "cluster"}]
        }
      ])
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "main"}}
      )

    B.build_resource(:monitoring_service_monitor)
    |> B.name("loki")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:config_map_data_source, battery, state) do
    namespace = core_namespace(state)
    contents = battery |> datasources_contents(state) |> to_yaml()
    data = %{"loki-datasources.yaml" => contents}

    B.build_resource(:config_map)
    |> B.name("loki-datasources")
    |> B.namespace(namespace)
    |> B.label("grafana_datasource", "1")
    |> B.data(data)
    |> F.require_battery(state, :grafana)
  end

  defp config_contents(battery, _state) do
    %{
      "auth_enabled" => false,
      "common" => %{
        "path_prefix" => "/var/loki",
        "replication_factor" => battery.config.replication_factor,
        "storage" => %{
          "filesystem" => %{
            "chunks_directory" => "/var/loki/chunks",
            "rules_directory" => "/var/loki/rules"
          }
        }
      },
      "limits_config" => %{
        "enforce_metric_name" => false,
        "max_cache_freshness_per_query" => "10m",
        "reject_old_samples" => true,
        "reject_old_samples_max_age" => "168h",
        "split_queries_by_interval" => "15m"
      },
      "memberlist" => %{"join_members" => ["loki-memberlist"]},
      "query_range" => %{"align_queries_with_step" => true},
      "schema_config" => %{
        "configs" => [
          %{
            "from" => "2022-01-11",
            "index" => %{"period" => "24h", "prefix" => "loki_index_"},
            "object_store" => "filesystem",
            "schema" => "v12",
            "store" => "boltdb-shipper"
          }
        ]
      },
      "server" => %{"grpc_listen_port" => 9095, "http_listen_port" => 3100},
      "storage_config" => %{
        "hedging" => %{"at" => "250ms", "max_per_second" => 20, "up_to" => 3}
      }
    }
  end

  defp datasources_contents(_battery, state) do
    namespace = core_namespace(state)

    %{
      apiVersion: 1,
      datasources: [
        %{
          name: "Loki",
          type: "loki",
          url: "http://loki.#{namespace}.svc:3100",
          version: 1,
          isDefault: false,
          jsonData: %{}
        }
      ]
    }
  end
end
