defmodule KubeResources.Battery do
  @moduledoc false

  alias KubeResources.BatterySettings
  alias KubeResources.EchoServer
  alias KubeResources.Ingress

  alias KubeExt.Builder, as: B

  @app_name "battery-control"
  @service_account "battery-control-account"

  defp namespace(config) do
    ns = BatterySettings.namespace(config)

    :namespace
    |> B.build_resource()
    |> B.name(ns)
  end

  def deployment(%{"control.run" => true} = config) do
    namespace = BatterySettings.namespace(config)
    name = BatterySettings.control_server_name(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{"battery/managed" => "True", "battery/app" => name},
        "name" => name,
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{"battery/app" => name}
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{"battery/managed" => "True", "battery/app" => name}
          },
          "spec" => %{
            "initContainers" => [
              control_container(config,
                name: "migrate",
                base: %{"command" => ["bin/control_server_migrate"]}
              )
            ],
            "containers" => [
              control_container(config,
                name: name,
                base: %{
                  "command" => ["bin/control_server", "start"],
                  "ports" => [%{"containerPort" => 4000}]
                }
              )
            ],
            "serviceAccountName" => @service_account
          }
        }
      }
    }
  end

  def deployment(_) do
    []
  end

  defp control_container(config, options) do
    base = Keyword.get(options, :base, %{})
    name = Keyword.get(options, :name, BatterySettings.control_server_name(config))
    version = Keyword.get(options, :version, BatterySettings.control_server_version(config))
    image = Keyword.get(options, :image, BatterySettings.control_server_image(config))

    Map.merge(
      base,
      %{
        "name" => name,
        "env" => [
          %{
            "name" => "POSTGRES_HOST",
            "value" => "postgres.default.svc.cluster.local"
          },
          %{
            "name" => "POSTGRES_DB",
            "value" => "control-dev"
          },
          %{
            "name" => "SECRET_KEY_BASE",
            "value" => "TEST_ING"
          },
          %{
            "name" => "POSTGRES_USER",
            "value" => "batterydbuser"
          },
          %{
            "name" => "POSTGRES_PASSWORD",
            "value" => "batterypasswd"
          },
          %{"name" => "MIX_ENV", "value" => "prod"},
          %{
            "name" => "BELLA_POD_NAME",
            "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
          },
          %{
            "name" => "BELLA_POD_NAMESPACE",
            "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
          },
          %{
            "name" => "BELLA_POD_IP",
            "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
          },
          %{
            "name" => "BELLA_POD_SERVICE_ACCOUNT",
            "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.serviceAccountName"}}
          }
        ],
        "image" => "#{image}:#{version}",
        "resources" => %{
          "limits" => %{"cpu" => "200m", "memory" => "200Mi"},
          "requests" => %{"cpu" => "200m", "memory" => "200Mi"}
        }
      }
    )
  end

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "labels" => %{"battery/managed" => "True", "battery/app" => "control-server"},
        "name" => "control-server-account"
      },
      "rules" => [
        %{
          "apiGroups" => ["apiextensions.k8s.io"],
          "resources" => ["customresourcedefinitions"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["k8s.batteriesincl.com"],
          "resources" => ["batteryclusters"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["policy"],
          "resources" => ["poddisruptionbudgets"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => [""],
          "resources" => [
            "secrets",
            "pods",
            "configmaps",
            "serviceaccounts",
            "services",
            "namespaces",
            "events"
          ],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["apiextensions.k8s.io"],
          "resources" => ["customresourcedefinitions"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["apps"],
          "resources" => ["deployments", "statefulsets"],
          "verbs" => ["*"]
        },
        %{"apiGroups" => ["batch"], "resources" => ["jobs", "cronjobs"], "verbs" => ["*"]},
        %{
          "apiGroups" => ["rbac.authorization.k8s.io"],
          "resources" => ["clusterroles", "clusterrolebindings"],
          "verbs" => ["*"]
        }
      ]
    }
  end

  def service_account(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name(@service_account)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def cluster_role_binding(config) do
    namespace = BatterySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "labels" => %{"battery/managed" => "True", "battery/app" => "control-server"},
        "name" => "control-server-account"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "control-server-account"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "control-server-account",
          "namespace" => namespace
        }
      ]
    }
  end

  def materialize(config) do
    %{
      "/0/namespace" => namespace(config),
      "/1/cluster_role" => cluster_role(config),
      "/1/service_account" => service_account(config),
      "/1/cluster_role_binding" => cluster_role_binding(config),
      "/1/deployment" => deployment(config),
      "/2/ingress" => Ingress.battery_ingress(config),
      "/3/echo/service" => EchoServer.service(config),
      "/3/echo/deployment" => EchoServer.deployment(config)
    }
  end
end
