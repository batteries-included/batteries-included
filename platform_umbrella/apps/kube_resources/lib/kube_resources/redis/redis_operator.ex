defmodule KubeResources.RedisOperator do
  use CommonCore.IncludeResource,
    redisfailovers_databases_spotahome_com:
      "priv/manifests/redis_operator/redisfailovers_databases_spotahome_com.yaml"

  use KubeExt.ResourceGenerator, app_name: "redis-operator"

  import CommonCore.Yaml
  import CommonCore.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F

  resource(:cluster_role_binding_redis_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("redis-operator")
    |> B.role_ref(B.build_cluster_role_ref("redis-operator"))
    |> B.subject(B.build_service_account("redis-operator", namespace))
  end

  resource(:cluster_role_redis_operator) do
    rules = [
      %{
        "apiGroups" => ["databases.spotahome.com"],
        "resources" => ["redisfailovers", "redisfailovers/finalizers"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["create", "get", "list", "update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "pods",
          "services",
          "endpoints",
          "events",
          "configmaps",
          "persistentvolumeclaims",
          "persistentvolumeclaims/finalizers"
        ],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["apps"],
        "resources" => ["deployments", "statefulsets"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["policy"],
        "resources" => ["poddisruptionbudgets"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("redis-operator")
    |> B.component_label("redis-operator")
    |> B.rules(rules)
  end

  resource(:crd_redisfailovers_databases_spotahome_com) do
    yaml(get_resource(:redisfailovers_databases_spotahome_com))
  end

  resource(:deployment_redis_operator, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "battery/component" => "redis-operator"
          }
        }
      )
      |> Map.put("strategy", %{"type" => "RollingUpdate"})
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => "redis-operator",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "image" => battery.config.operator_image,
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "failureThreshold" => 6,
                  "initialDelaySeconds" => 30,
                  "periodSeconds" => 5,
                  "successThreshold" => 1,
                  "tcpSocket" => %{"port" => 9710},
                  "timeoutSeconds" => 5
                },
                "name" => "redis-operator",
                "ports" => [%{"containerPort" => 9710, "name" => "metrics", "protocol" => "TCP"}],
                "readinessProbe" => %{
                  "initialDelaySeconds" => 10,
                  "periodSeconds" => 3,
                  "tcpSocket" => %{"port" => 9710},
                  "timeoutSeconds" => 3
                },
                "resources" => %{
                  "limits" => %{"cpu" => "100m", "memory" => "128Mi"},
                  "requests" => %{"cpu" => "100m", "memory" => "128Mi"}
                },
                "securityContext" => %{
                  "readOnlyRootFilesystem" => true,
                  "runAsNonRoot" => true,
                  "runAsUser" => 1000
                }
              }
            ],
            "serviceAccountName" => "redis-operator"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("redis-operator")
    |> B.namespace(namespace)
    |> B.component_label("redis-operator")
    |> B.spec(spec)
  end

  resource(:service_account_redis_operator, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("redis-operator")
    |> B.namespace(namespace)
    |> B.component_label("redis-operator")
  end

  resource(:service_monitor_redis_operator, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"interval" => "15s", "port" => "metrics"}])
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "battery/component" => "redis-operator"
          }
        }
      )

    B.build_resource(:monitoring_service_monitor)
    |> B.name("redis-operator")
    |> B.namespace(namespace)
    |> B.component_label("redis-operator")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_redis_operator, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"name" => "metrics", "port" => 9710, "protocol" => "TCP"}])
      |> Map.put(
        "selector",
        %{"battery/app" => @app_name, "battery/component" => "redis-operator"}
      )

    B.build_resource(:service)
    |> B.name("redis-operator")
    |> B.namespace(namespace)
    |> B.component_label("redis-operator")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
