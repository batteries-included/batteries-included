defmodule CommonCore.Resources.Keycloak do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "keycloak"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.IstioConfig.VirtualService
  alias CommonCore.Resources.Secret

  resource(:config_map_env_vars, battery, state) do
    namespace = core_namespace(state)
    basenamespace = base_namespace(state)

    data =
      %{}
      |> Map.put("KC_HEALTH_ENABLED", "true")
      |> Map.put("KC_CACHE", "ispn")
      |> Map.put("KC_CACHE_STACK", "kubernetes")
      |> Map.put("KC_HOSTNAME_STRICT", "false")
      |> Map.put("KC_HOSTNAME_STRICT_BACKCHANNEL", "false")
      |> Map.put("KC_HTTP_ENABLED", "true")
      |> Map.put("KC_HTTP_PORT", "8080")
      |> Map.put("KC_PROXY", "edge")
      |> Map.put("KC_DB", "postgres")
      |> Map.put("KC_DB_URL_HOST", "pg-auth.#{basenamespace}.svc")
      |> Map.put("KC_LOG_LEVEL", "info")
      |> Map.put("KEYCLOAK_ADMIN", battery.config.admin_username)
      |> Map.put("jgroups.dns.query", "keycloak-headless.#{namespace}")

    :config_map
    |> B.build_resource()
    |> B.name("keycloak-env-vars")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_main, battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("admin-password", battery.config.admin_password)
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_account_main, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name("keycloak")
    |> B.namespace(namespace)
  end

  resource(:service_headless, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 80, "protocol" => "TCP", "targetPort" => "http"}
      ])
      |> Map.put("publishNotReadyAddresses", true)
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("keycloak-headless")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 80, "protocol" => "TCP", "targetPort" => "http"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:stateful_set_main, battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("podManagementPolicy", "Parallel")
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )
      |> Map.put("serviceName", "keycloak-headless")
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
            "affinity" => %{
              "podAntiAffinity" => %{
                "preferredDuringSchedulingIgnoredDuringExecution" => [
                  %{
                    "podAffinityTerm" => %{
                      "labelSelector" => %{
                        "matchLabels" => %{"battery/app" => @app_name}
                      },
                      "topologyKey" => "kubernetes.io/hostname"
                    },
                    "weight" => 1
                  }
                ]
              }
            },
            "containers" => [
              %{
                "env" => [
                  %{
                    "name" => "KUBERNETES_NAMESPACE",
                    "valueFrom" => %{
                      "fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.namespace"}
                    }
                  },
                  %{
                    "name" => "KEYCLOAK_ADMIN_PASSWORD",
                    "valueFrom" => %{
                      "secretKeyRef" => %{"key" => "admin-password", "name" => "keycloak"}
                    }
                  },
                  %{
                    "name" => "KC_DB_USERNAME",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "username",
                        "name" => "keycloak.pg-auth.credentials.postgresql"
                      }
                    }
                  },
                  %{
                    "name" => "KC_DB_PASSWORD",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "password",
                        "name" => "keycloak.pg-auth.credentials.postgresql"
                      }
                    }
                  },
                  %{"name" => "KEYCLOAK_HTTP_RELATIVE_PATH", "value" => "/"}
                ],
                "envFrom" => [%{"configMapRef" => %{"name" => "keycloak-env-vars"}}],
                "image" => battery.config.image,
                "args" => ["start-dev", "--features=preview"],
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/", "port" => "http"},
                  "initialDelaySeconds" => 300,
                  "periodSeconds" => 1,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 5
                },
                "name" => "keycloak",
                "ports" => [%{"containerPort" => 8080, "name" => "http", "protocol" => "TCP"}],
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/realms/master", "port" => "http"},
                  "initialDelaySeconds" => 30,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "resources" => %{"limits" => %{}, "requests" => %{}},
                "securityContext" => %{"runAsNonRoot" => true, "runAsUser" => 1001}
              }
            ],
            "securityContext" => %{"fsGroup" => 1001},
            "serviceAccountName" => "keycloak"
          }
        }
      )
      |> Map.put("updateStrategy", %{"rollingUpdate" => %{}, "type" => "RollingUpdate"})

    :stateful_set
    |> B.build_resource()
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("keycloak", hosts: [keycloak_host(state)])

    :istio_virtual_service
    |> B.build_resource()
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end
end
