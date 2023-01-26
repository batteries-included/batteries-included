defmodule KubeResources.OryHydra do
  use CommonCore.IncludeResource,
    oauth2clients_hydra_ory_sh: "priv/manifests/ory_hydra/oauth2clients_hydra_ory_sh.yaml",
    hydra_yaml: "priv/raw_files/ory_hydra/hydra.yaml"

  use KubeExt.ResourceGenerator, app_name: "ory-hydra"
  import CommonCore.Yaml
  import CommonCore.SystemState.Namespaces
  import CommonCore.SystemState.Hosts

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeExt.Secret
  alias KubeResources.IstioConfig.VirtualService

  resource(:cluster_role_binding_ory_hydra_hydra_maester, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("ory-hydra-hydra-maester-role-binding")
    |> B.component_label("hydra-maester")
    |> B.role_ref(B.build_cluster_role_ref("ory-hydra-hydra-maester-role"))
    |> B.subject(B.build_service_account("ory-hydra-hydra-maester-account", namespace))
  end

  resource(:cluster_role_ory_hydra_hydra_maester) do
    rules = [
      %{
        "apiGroups" => ["hydra.ory.sh"],
        "resources" => ["oauth2clients", "oauth2clients/status"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["list", "watch", "create"]}
    ]

    B.build_resource(:cluster_role) |> B.name("ory-hydra-hydra-maester-role") |> B.rules(rules)
  end

  resource(:role_binding_ory_hydra_hydra_maester, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("ory-hydra-hydra-maester-role-binding")
    |> B.namespace(namespace)
    |> B.component_label("hydra-maester")
    |> B.role_ref(B.build_role_ref("ory-hydra-hydra-maester-role"))
    |> B.subject(B.build_service_account("ory-hydra-hydra-maester-account", namespace))
  end

  resource(:role_ory_hydra_hydra_maester, _battery, state) do
    namespace = core_namespace(state)

    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch", "create"]
      },
      %{
        "apiGroups" => ["hydra.ory.sh"],
        "resources" => ["oauth2clients", "oauth2clients/status"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      }
    ]

    B.build_resource(:role)
    |> B.name("ory-hydra-hydra-maester-role")
    |> B.namespace(namespace)
    |> B.component_label("hydra-maester")
    |> B.rules(rules)
  end

  resource(:service_account_ory_hydra, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("ory-hydra")
    |> B.namespace(namespace)
    |> B.component_label("hydra")
  end

  resource(:service_account_ory_hydra_hydra_maester, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:service_account)
    |> B.name("ory-hydra-hydra-maester-account")
    |> B.namespace(namespace)
    |> B.component_label("hydra-maester")
  end

  resource(:crd_oauth2clients_hydra_ory_sh) do
    yaml(get_resource(:oauth2clients_hydra_ory_sh))
  end

  resource(:config_map_ory_hydra, _battery, state) do
    namespace = core_namespace(state)
    data = %{"hydra.yaml" => get_resource(:hydra_yaml)}

    B.build_resource(:config_map)
    |> B.name("ory-hydra")
    |> B.namespace(namespace)
    |> B.component_label("hydra")
    |> B.data(data)
  end

  resource(:deployment_ory_hydra, battery, state) do
    namespace = core_namespace(state)

    template = %{
      "metadata" => %{
        "annotations" => nil,
        "labels" => %{
          "battery/app" => @app_name,
          "battery/component" => "hydra",
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "args" => ["serve", "all", "--dev", "--config", "/etc/config/hydra.yaml"],
            "command" => ["hydra"],
            "env" => [
              %{"name" => "URLS_SELF_ISSUER", "value" => "http://127.0.0.1:4444/"},
              %{
                "name" => "SECRETS_SYSTEM",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "secretsSystem", "name" => "ory-hydra"}
                }
              },
              %{
                "name" => "SECRETS_COOKIE",
                "valueFrom" => %{
                  "secretKeyRef" => %{"key" => "secretsCookie", "name" => "ory-hydra"}
                }
              },
              %{
                "name" => "POSTGRES_USER",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "username",
                    "name" => "oryhydra.pg-auth.credentials.postgresql",
                    "optional" => false
                  }
                }
              },
              %{
                "name" => "POSTGRES_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "password",
                    "name" => "oryhydra.pg-auth.credentials.postgresql",
                    "optional" => false
                  }
                }
              },
              %{
                "name" => "DSN",
                "value" =>
                  "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@pg-auth.battery-base.svc/hydra?sslmode=prefer"
              }
            ],
            "image" => battery.config.hydra_image,
            "imagePullPolicy" => "IfNotPresent",
            "lifecycle" => %{},
            "livenessProbe" => %{
              "failureThreshold" => 5,
              "httpGet" => %{
                "httpHeaders" => [%{"name" => "Host", "value" => "127.0.0.1"}],
                "path" => "/health/alive",
                "port" => 4445
              },
              "initialDelaySeconds" => 5,
              "periodSeconds" => 10
            },
            "name" => "hydra",
            "ports" => [
              %{"containerPort" => 4444, "name" => "http-public", "protocol" => "TCP"},
              %{"containerPort" => 4445, "name" => "http-admin", "protocol" => "TCP"}
            ],
            "readinessProbe" => %{
              "failureThreshold" => 5,
              "httpGet" => %{
                "httpHeaders" => [%{"name" => "Host", "value" => "127.0.0.1"}],
                "path" => "/health/ready",
                "port" => 4445
              },
              "initialDelaySeconds" => 5,
              "periodSeconds" => 10
            },
            "resources" => %{},
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "privileged" => false,
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true,
              "runAsUser" => 100
            },
            "startupProbe" => %{
              "failureThreshold" => 60,
              "httpGet" => %{
                "httpHeaders" => [%{"name" => "Host", "value" => "127.0.0.1"}],
                "path" => "/health/ready",
                "port" => 4445
              },
              "periodSeconds" => 1,
              "successThreshold" => 1,
              "timeoutSeconds" => 1
            },
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/config",
                "name" => "hydra-config-volume",
                "readOnly" => true
              }
            ]
          }
        ],
        "initContainers" => [
          %{
            "args" => ["migrate", "sql", "-e", "--yes", "--config", "/etc/config/hydra.yaml"],
            "command" => ["hydra"],
            "image" => battery.config.hydra_image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "hydra-automigrate",
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/config",
                "name" => "hydra-config-volume",
                "readOnly" => true
              }
            ],
            "env" => [
              %{
                "name" => "POSTGRES_USER",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "username",
                    "name" => "oryhydra.pg-auth.credentials.postgresql",
                    "optional" => false
                  }
                }
              },
              %{
                "name" => "POSTGRES_PASSWORD",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "password",
                    "name" => "oryhydra.pg-auth.credentials.postgresql",
                    "optional" => false
                  }
                }
              },
              %{
                "name" => "DSN",
                "value" =>
                  "postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@pg-auth.battery-base.svc/hydra?sslmode=prefer"
              }
            ]
          }
        ],
        "serviceAccountName" => "ory-hydra",
        "volumes" => [
          %{"configMap" => %{"name" => "ory-hydra"}, "name" => "hydra-config-volume"}
        ]
      }
    }

    spec =
      %{}
      |> Map.put("replicas", battery.config.hydra_replicas)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "hydra"}}
      )
      |> Map.put("template", template)

    B.build_resource(:deployment)
    |> B.name("ory-hydra")
    |> B.namespace(namespace)
    |> B.component_label("hydra")
    |> B.spec(spec)
  end

  resource(:deployment_ory_hydra_hydra_maester, battery, state) do
    namespace = core_namespace(state)

    template = %{
      "metadata" => %{
        "annotations" => nil,
        "labels" => %{
          "battery/app" => @app_name,
          "battery/component" => "hydra-maester",
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "args" => [
              "--metrics-addr=127.0.0.1:8080",
              "--hydra-url=http://ory-hydra-admin",
              "--hydra-port=4445",
              "--endpoint=/admin/clients"
            ],
            "command" => ["/manager"],
            "image" => battery.config.hydra_maester_image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "hydra-maester",
            "resources" => %{},
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "privileged" => false,
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true,
              "runAsUser" => 1000
            },
            "terminationMessagePath" => "/dev/termination-log",
            "terminationMessagePolicy" => "File"
          }
        ],
        "nodeSelector" => nil,
        "serviceAccountName" => "ory-hydra-hydra-maester-account"
      }
    }

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => @app_name, "battery/component" => "hydra-maester"}
      })
      |> Map.put("template", template)

    B.build_resource(:deployment)
    |> B.name("ory-hydra-hydra-maester")
    |> B.namespace(namespace)
    |> B.component_label("hydra-maester")
    |> B.spec(spec)
  end

  resource(:secret_ory_hydra, battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("secretsSystem", battery.config.hydra_secret_system)
      |> Map.put("secretsCookie", battery.config.hydra_secret_cookie)
      |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("ory-hydra")
    |> B.namespace(namespace)
    |> B.component_label("hydra")
    |> B.data(data)
  end

  resource(:service_ory_hydra_admin, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 4445, "protocol" => "TCP", "targetPort" => "http-admin"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "hydra"})

    B.build_resource(:service)
    |> B.name("ory-hydra-admin")
    |> B.namespace(namespace)
    |> B.component_label("admin")
    |> B.component_label("hydra")
    |> B.spec(spec)
  end

  resource(:service_ory_hydra_public, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => 4444, "protocol" => "TCP", "targetPort" => "http-public"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "hydra"})

    B.build_resource(:service)
    |> B.name("ory-hydra-public")
    |> B.namespace(namespace)
    |> B.component_label("hydra")
    |> B.spec(spec)
  end

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("ory-hydra-public", hosts: [hydra_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("hydra")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:virtual_service_admin, _battery, state) do
    namespace = core_namespace(state)

    spec = VirtualService.fallback("ory-hydra-admin", hosts: [hydra_admin_host(state)])

    B.build_resource(:istio_virtual_service)
    |> B.name("hydra-admin")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end
end
