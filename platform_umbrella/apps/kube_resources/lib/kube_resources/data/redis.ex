defmodule KubeResources.Redis do
  @moduledoc false
  use KubeExt.IncludeResource,
    crd: "priv/manifests/redis/databases.spotahome.com_redisfailovers.yaml"

  import KubeExt.Yaml

  alias ControlServer.Redis
  alias ControlServer.Redis.FailoverCluster
  alias KubeExt.Builder, as: B
  alias KubeRawResources.DataSettings

  @app "redisoperator"
  @service_account_name "redisoperator"

  def materialize(config) do
    config
    |> materialize_static()
    |> Map.merge(redis_failover_clusters(config))
  end

  def materialize_static(config) do
    %{
      "/crd" => crd(config),
      "/deployment" => deployment(config),
      "/cluster_role_binding" => cluster_role_binding(config),
      "/cluster_role" => cluster_role(config),
      "/service_account" => service_account(config)
    }
  end

  def redis_failover_clusters(config) do
    Redis.list_failover_clusters()
    |> Enum.map(fn cluster ->
      {"/failover_cluster/" <> cluster.id, redis_failover_cluster(cluster, config)}
    end)
    |> Enum.into(%{})
  end

  defp cluster_namespace(%FailoverCluster{type: :internal} = _cluster, config),
    do: DataSettings.namespace(config)

  defp cluster_namespace(%FailoverCluster{type: _} = _cluster, config),
    do: DataSettings.public_namespace(config)

  def redis_failover_cluster(%FailoverCluster{} = cluster, config) do
    namespace = cluster_namespace(cluster, config)
    spec = failover_spec(cluster)

    B.build_resource(:redis_failover)
    |> B.namespace(namespace)
    |> B.name(cluster.name)
    |> B.app_labels(@app)
    |> B.spec(spec)
    |> B.owner_label(cluster.id)
  end

  defp failover_spec(%FailoverCluster{} = cluster) do
    %{
      "sentinel" => %{
        "replicas" => FailoverCluster.num_sentinel_instances(cluster)
      },
      "redis" => %{
        "replicas" => FailoverCluster.num_redis_instances(cluster)
      }
    }
  end

  def crd(_), do: yaml(get_resource(:crd))

  def deployment(config) do
    namespace = DataSettings.public_namespace(config)

    image = DataSettings.redis_operator_image(config)

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app
        }
      },
      "strategy" => %{
        "type" => "RollingUpdate"
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => @app,
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "image" => image,
              "imagePullPolicy" => "IfNotPresent",
              "name" => "app",
              "resources" => %{
                "limits" => %{
                  "cpu" => "100m",
                  "memory" => "50Mi"
                },
                "requests" => %{
                  "cpu" => "10m",
                  "memory" => "50Mi"
                }
              },
              "securityContext" => %{
                "readOnlyRootFilesystem" => true,
                "runAsNonRoot" => true,
                "runAsUser" => 1000
              }
            }
          ],
          "restartPolicy" => "Always",
          "serviceAccountName" => @service_account_name
        }
      }
    }

    B.build_resource(:deployment)
    |> B.name("redisoperator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def cluster_role_binding(config) do
    namespace = DataSettings.public_namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-redisoperator"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-redisoperator"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => @service_account_name,
          "namespace" => namespace
        }
      ]
    }
  end

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-redisoperator"
      },
      "rules" => [
        %{
          "apiGroups" => [
            "databases.spotahome.com"
          ],
          "resources" => [
            "redisfailovers",
            "redisfailovers/finalizers"
          ],
          "verbs" => [
            "*"
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
            "*"
          ]
        },
        %{
          "apiGroups" => [
            ""
          ],
          "resources" => [
            "pods",
            "services",
            "endpoints",
            "events",
            "configmaps",
            "persistentvolumeclaims",
            "persistentvolumeclaims/finalizers"
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
            "secrets"
          ],
          "verbs" => [
            "get"
          ]
        },
        %{
          "apiGroups" => [
            "apps"
          ],
          "resources" => [
            "deployments",
            "statefulsets"
          ],
          "verbs" => [
            "*"
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
            "*"
          ]
        }
      ]
    }
  end

  def service_account(config) do
    namespace = DataSettings.public_namespace(config)

    B.build_resource(:service_account)
    |> B.name(@service_account_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end
end
