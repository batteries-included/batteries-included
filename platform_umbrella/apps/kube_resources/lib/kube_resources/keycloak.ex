defmodule KubeResources.Keycloak do
  use KubeResources.ResourceGenerator, app_name: "keycloak"

  import CommonCore.StateSummary.Namespaces
  import CommonCore.StateSummary.Hosts

  alias KubeResources.Builder, as: B
  alias KubeResources.FilterResource, as: F
  alias KubeResources.Secret
  alias KubeResources.IstioConfig.VirtualService

  resource(:config_map_env_vars, _battery, state) do
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
      |> Map.put("KEYCLOAK_ADMIN", "batteryadmin")
      |> Map.put("jgroups.dns.query", "keycloak-headless.#{namespace}")

    B.build_resource(:config_map)
    |> B.name("keycloak-env-vars")
    |> B.namespace(namespace)
    |> B.component_label("keycloak")
    |> B.data(data)
  end

  resource(:secret_main, _battery, state) do
    namespace = core_namespace(state)
    data = %{} |> Map.put("admin-password", "testing") |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.component_label("keycloak")
    |> B.data(data)
  end

  resource(:service_account_main, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> Map.put("automountServiceAccountToken", true)
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.component_label("keycloak")
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

    B.build_resource(:service)
    |> B.name("keycloak-headless")
    |> B.namespace(namespace)
    |> B.component_label("keycloak")
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

    B.build_resource(:service)
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.component_label("keycloak")
    |> B.spec(spec)
  end

  resource(:stateful_set_main, _battery, state) do
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
                "image" => "quay.io/keycloak/keycloak:20.0.3",
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

    B.build_resource(:stateful_set)
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.component_label("keycloak")
    |> B.spec(spec)
  end

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("keycloak", hosts: [keycloak_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("keycloak")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end
end
