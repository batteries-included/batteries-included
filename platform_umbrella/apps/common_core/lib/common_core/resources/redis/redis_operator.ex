defmodule CommonCore.Resources.RedisOperator do
  @moduledoc false
  use CommonCore.IncludeResource,
    redis_redis_redis_opstreelabs_in: "priv/manifests/redis-operator/redis_redis_redis_opstreelabs_in.yaml",
    redisclusters_redis_redis_opstreelabs_in:
      "priv/manifests/redis-operator/redisclusters_redis_redis_opstreelabs_in.yaml",
    redisreplications_redis_redis_opstreelabs_in:
      "priv/manifests/redis-operator/redisreplications_redis_redis_opstreelabs_in.yaml",
    redissentinels_redis_redis_opstreelabs_in:
      "priv/manifests/redis-operator/redissentinels_redis_redis_opstreelabs_in.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "redis-operator"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  resource(:service_account_redis_operator, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name("redis-operator")
    |> B.namespace(namespace)
  end

  resource(:cluster_role_binding_redis_operator, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("redis-operator")
    |> B.role_ref(B.build_cluster_role_ref("redis-operator"))
    |> B.subject(B.build_service_account("redis-operator", namespace))
  end

  resource(:cluster_role_redis_operator) do
    rules = [
      %{
        "apiGroups" => ["redis.redis.opstreelabs.in"],
        "resources" => [
          "rediss",
          "redisclusters",
          "redisreplications",
          "redis",
          "rediscluster",
          "redissentinel",
          "redissentinels",
          "redisreplication"
        ],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{"nonResourceURLs" => ["*"], "verbs" => ["get"]},
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["redis.redis.opstreelabs.in"],
        "resources" => [
          "redis/finalizers",
          "rediscluster/finalizers",
          "redisclusters/finalizers",
          "redissentinel/finalizers",
          "redissentinels/finalizers",
          "redisreplication/finalizers",
          "redisreplications/finalizers"
        ],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["redis.redis.opstreelabs.in"],
        "resources" => [
          "redis/status",
          "rediscluster/status",
          "redisclusters/status",
          "redissentinel/status",
          "redissentinels/status",
          "redisreplication/status",
          "redisreplications/status"
        ],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "secrets",
          "pods/exec",
          "pods",
          "services",
          "configmaps",
          "events",
          "persistentvolumeclaims",
          "namespace"
        ],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["statefulsets"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["policy"],
        "resources" => ["poddisruptionbudgets"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("redis-operator")
    |> B.rules(rules)
  end

  resource(:crd_redis_redis_redis_opstreelabs_in) do
    YamlElixir.read_all_from_string!(get_resource(:redis_redis_redis_opstreelabs_in))
  end

  resource(:crd_redisclusters_redis_redis_opstreelabs_in) do
    YamlElixir.read_all_from_string!(get_resource(:redisclusters_redis_redis_opstreelabs_in))
  end

  resource(:crd_redisreplications_redis_redis_opstreelabs_in) do
    YamlElixir.read_all_from_string!(get_resource(:redisreplications_redis_redis_opstreelabs_in))
  end

  resource(:crd_redissentinels_redis_redis_opstreelabs_in) do
    YamlElixir.read_all_from_string!(get_resource(:redissentinels_redis_redis_opstreelabs_in))
  end

  resource(:deployment_redis_operator, battery, state) do
    namespace = core_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{"labels" => %{"battery/managed" => "true"}})
      |> Map.put("spec", %{
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "args" => ["--leader-elect"],
            "command" => ["/operator", "manager"],
            "env" => [%{"name" => "ENABLE_WEBHOOKS", "value" => "false"}],
            "image" => battery.config.operator_image,
            "imagePullPolicy" => "Always",
            "livenessProbe" => %{"httpGet" => %{"path" => "/healthz", "port" => 8081}},
            "name" => "redis-operator",
            "readinessProbe" => %{"httpGet" => %{"path" => "/readyz", "port" => 8081}},
            "resources" => %{
              "limits" => %{"cpu" => "500m", "memory" => "500Mi"},
              "requests" => %{"cpu" => "500m", "memory" => "500Mi"}
            },
            "securityContext" => %{}
          }
        ],
        "securityContext" => %{},
        "serviceAccount" => "redis-operator",
        "serviceAccountName" => "redis-operator"
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("redis-operator")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_webhook, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"port" => 443, "protocol" => "TCP", "targetPort" => 9443}])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("webhook-service")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end
end
