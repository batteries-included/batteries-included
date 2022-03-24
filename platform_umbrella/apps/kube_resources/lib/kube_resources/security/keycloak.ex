defmodule KubeResources.Keycloak do
  @moduledoc false
  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeRawResources.Keycloak, as: RawKeycloak
  alias KubeResources.SecuritySettings

  @app "keycloak"

  @service_account_name "keycloak-operator"

  @crd_path "priv/manifests/keycloak/keycloak.crds.yaml"

  def materialize(config) do
    %{
      "/1/crd" => crd(config),
      "/1/service_account" => service_account(config),
      "/1/role" => role(config),
      "/1/role_binding" => role_binding(config),
      "/1/deployment" => deployment(config),
      "/2/keycloak" => keycloak(config)
    }
  end

  def crd(_), do: yaml(crd_content())

  def service_account(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name(@service_account_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def role(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{"name" => "keycloak-operator", "namespace" => namespace},
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => [
            "pods",
            "services",
            "services/finalizers",
            "endpoints",
            "persistentvolumeclaims",
            "events",
            "configmaps",
            "secrets"
          ],
          "verbs" => ["list", "get", "create", "patch", "update", "watch", "delete"]
        },
        %{
          "apiGroups" => ["apps"],
          "resources" => ["deployments", "daemonsets", "replicasets", "statefulsets"],
          "verbs" => ["list", "get", "create", "update", "watch"]
        },
        %{
          "apiGroups" => ["batch"],
          "resources" => ["cronjobs", "jobs"],
          "verbs" => ["list", "get", "create", "update", "watch"]
        },
        %{
          "apiGroups" => ["route.openshift.io"],
          "resources" => ["routes/custom-host"],
          "verbs" => ["create"]
        },
        %{
          "apiGroups" => ["route.openshift.io"],
          "resources" => ["routes"],
          "verbs" => ["list", "get", "create", "update", "watch"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingresses"],
          "verbs" => ["list", "get", "create", "update", "watch"]
        },
        %{
          "apiGroups" => ["monitoring.coreos.com"],
          "resources" => ["servicemonitors", "prometheusrules"],
          "verbs" => ["list", "get", "create", "update", "watch"]
        },
        %{
          "apiGroups" => ["integreatly.org"],
          "resources" => ["grafanadashboards"],
          "verbs" => ["get", "list", "create", "update", "watch"]
        },
        %{
          "apiGroups" => ["apps"],
          "resourceNames" => ["keycloak-operator"],
          "resources" => ["deployments/finalizers"],
          "verbs" => ["update"]
        },
        %{
          "apiGroups" => ["policy"],
          "resources" => ["poddisruptionbudgets"],
          "verbs" => ["get", "list", "create", "update", "watch"]
        },
        %{
          "apiGroups" => ["keycloak.org"],
          "resources" => [
            "keycloaks",
            "keycloaks/status",
            "keycloaks/finalizers",
            "keycloakrealms",
            "keycloakrealms/status",
            "keycloakrealms/finalizers",
            "keycloakclients",
            "keycloakclients/status",
            "keycloakclients/finalizers",
            "keycloakbackups",
            "keycloakbackups/status",
            "keycloakbackups/finalizers",
            "keycloakusers",
            "keycloakusers/status",
            "keycloakusers/finalizers"
          ],
          "verbs" => ["get", "list", "update", "watch"]
        }
      ]
    }
  end

  def role_binding(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name("keycloak-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> Map.put("roleRef", %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "Role",
      "name" => "keycloak-operator"
    })
    |> Map.put("subjects", [
      %{"kind" => "ServiceAccount", "name" => @service_account_name, "namespace" => namespace}
    ])
  end

  def deployment(config) do
    namespace = SecuritySettings.namespace(config)

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{"name" => "keycloak-operator", "battery/managed" => "true"}
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{"name" => "keycloak-operator", "battery/managed" => "true"}
        },
        "spec" => %{
          "containers" => [
            %{
              "command" => ["keycloak-operator"],
              "env" => [
                %{
                  "name" => "WATCH_NAMESPACE",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                },
                %{
                  "name" => "POD_NAME",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                },
                %{"name" => "OPERATOR_NAME", "value" => "keycloak-operator"}
              ],
              "image" => "quay.io/keycloak/keycloak-operator:17.0.0",
              "imagePullPolicy" => "Always",
              "name" => "keycloak-operator"
            }
          ],
          "serviceAccountName" => @service_account_name
        }
      }
    }

    B.build_resource(:deployment)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name("keycloak-operator")
    |> B.spec(spec)
  end

  def keycloak(config) do
    namespace = SecuritySettings.namespace(config)
    db_name = RawKeycloak.db_name()
    db_team = RawKeycloak.db_team()
    db_service_name = "#{db_team}-#{db_name}.#{namespace}.svc.cluster.local"

    metrics_version = SecuritySettings.keycloak_metrics_version(config)

    spec = %{
      "instances" => 1,
      "extensions" => [
        "https://github.com/aerogear/keycloak-metrics-spi/releases/download/#{metrics_version}/keycloak-metrics-spi-#{metrics_version}.jar"
      ],
      "externalAccess" => %{"enabled" => false},
      "podDisruptionBudget" => %{"enabled" => true},
      "externalDatabase" => %{"enabled" => true},

      # Set the database config
      "keycloakDeploymentSpec" => %{
        "experimental" => %{
          "env" => [
            %{
              "name" => "KEYCLOAK_POSTGRESQL_SERVICE_HOST",
              "value" => db_service_name
            },
            %{
              "name" => "DB_ADDR",
              "value" => db_service_name
            },
            %{
              "name" => "DB_USER",
              "valueFrom" => %{
                "secretKeyRef" => %{
                  "name" => "keycloakuser.pg-keycloak.credentials.postgresql.acid.zalan.do",
                  "key" => "username"
                }
              }
            },
            %{
              "name" => "DB_PASSWORD",
              "valueFrom" => %{
                "secretKeyRef" => %{
                  "name" => "keycloakuser.pg-keycloak.credentials.postgresql.acid.zalan.do",
                  "key" => "password"
                }
              }
            }
          ]
        }
      }
    }

    %{
      "apiVersion" => "keycloak.org/v1alpha1",
      "kind" => "Keycloak",
      "metadata" => %{
        "name" => "battery-keycloak",
        "namespace" => namespace,
        "labels" => %{"battery/app" => @app, "battery/managed" => "true"}
      },
      "spec" => spec
    }
  end

  defp crd_content, do: unquote(File.read!(@crd_path))
end
