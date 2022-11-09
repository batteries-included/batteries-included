defmodule KubeResources.OryHydra do
  @moduledoc false
  use KubeExt.IncludeResource, crd: "priv/manifests/ory_hydra/crd.yaml"

  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeResources.SecuritySettings
  alias KubeExt.Secret
  alias KubeExt.RequiredDatabases

  @app "ory-hyrda"

  @hydra_component "hydra"
  @maester_component "maester"

  @maester_service_account "hydra-maester"
  @hyrda_service_account "hydra"
  @jobs_service_account "hydra-jobs"

  @hydra_config_map "hydra-config"
  @hydra_secret "hydra"

  @maester_cluster_role "hydra-maester"
  @maester_role "hydra-maester"

  @admin_service "hydra-admin"
  @public_service "hydra-public"

  def crd(_, _), do: yaml(get_resource(:crd))

  def service_account_hydra_hydra_maester_account(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    B.build_resource(:service_account)
    |> B.namespace(namespace)
    |> B.name(@maester_service_account)
    |> B.app_labels(@app)
    |> B.component_label(@maester_component)
  end

  def service_account_hydra(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    B.build_resource(:service_account)
    |> B.namespace(namespace)
    |> B.name(@hyrda_service_account)
    |> B.app_labels(@app)
    |> B.component_label(@hydra_component)
  end

  def config_map_hydra(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    config = %{
      "serve" => %{
        "admin" => %{"port" => 4445},
        "public" => %{"port" => 4444},
        "tls" => %{
          "allow_termination_from" => ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
        }
      },
      "urls" => %{"self" => %{}}
    }

    B.build_resource(:config_map)
    |> B.namespace(namespace)
    |> B.name(@hydra_config_map)
    |> B.app_labels(@app)
    |> B.data(%{"config.yaml" => Ymlr.Encoder.to_s!(config)})
  end

  def cluster_role_hydra_hydra_maester_role(_battery, _state) do
    rules = [
      %{
        "apiGroups" => [
          "hydra.ory.sh"
        ],
        "resources" => [
          "oauth2clients",
          "oauth2clients/status"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "patch",
          "delete"
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
          "list",
          "watch",
          "create"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@maester_cluster_role)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def cluster_role_binding_hydra_hydra_maester_role_binding(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    B.build_resource(:cluster_role_binding)
    |> B.name("hydra-maester-role-binding")
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@maester_cluster_role))
    |> B.subject(B.build_service_account(@maester_service_account, namespace))
  end

  def role_hydra_hydra_maester_role_default(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.name(@maester_role)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def role_binding_hydra_hydra_maester_role_binding_default(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    B.build_resource(:role_binding)
    |> B.name("hydra-maester-role-binding")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@maester_role))
    |> B.subject(B.build_service_account(@maester_service_account, namespace))
  end

  def service_hydra_admin(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    spec = %{
      "ports" => [
        %{
          "name" => "http",
          "port" => 4445,
          "protocol" => "TCP",
          "targetPort" => "http-admin"
        }
      ],
      "selector" => %{
        "battery/app" => @app,
        "battery/component" => @hydra_component
      }
    }

    B.build_resource(:service)
    |> B.name(@admin_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label(@hydra_component)
    |> B.spec(spec)
  end

  def service_hydra_public(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    spec = %{
      "ports" => [
        %{
          "name" => "http",
          "port" => 4444,
          "protocol" => "TCP",
          "targetPort" => "http-public"
        }
      ],
      "selector" => %{
        "battery/app" => @app,
        "battery/component" => @hydra_component
      }
    }

    B.build_resource(:service)
    |> B.name(@public_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label(@hydra_component)
    |> B.spec(spec)
  end

  def deployment_hydra_hydra_maester(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)
    image = SecuritySettings.ory_maester_image(battery.config)

    template =
      %{}
      |> B.app_labels(@app)
      |> B.component_label(@maester_component)
      |> B.spec(%{
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "args" => [
              "--metrics-addr=127.0.0.1:8080",
              "--hydra-url=http://#{@admin_service}",
              "--hydra-port=4445"
            ],
            "command" => [
              "/manager"
            ],
            "image" => image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "hydra-maester",
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{
                "drop" => [
                  "ALL"
                ]
              },
              "privileged" => false,
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true,
              "runAsUser" => 1000
            },
            "terminationMessagePath" => "/dev/termination-log",
            "terminationMessagePolicy" => "File"
          }
        ],
        "serviceAccountName" => @maester_service_account
      })

    spec = %{
      "replicas" => 1,
      "revisionHistoryLimit" => 10,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app,
          "battery/component" => @maester_component
        }
      },
      "template" => template
    }

    B.build_resource(:deployment)
    |> B.app_labels(@app)
    |> B.component_label(@maester_component)
    |> B.name("hydra-maestra")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def deployment_hydra(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)
    image = SecuritySettings.ory_hydra_image(battery.config)

    template =
      %{}
      |> B.app_labels(@app)
      |> B.component_label(@hydra_component)
      |> B.spec(%{
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "args" => [
              "serve",
              "all",
              "--dangerous-force-http",
              "--config",
              "/etc/config/config.yaml"
            ],
            "command" => [
              "hydra"
            ],
            "env" => [
              %{
                "name" => "URLS_SELF_ISSUER",
                "value" => "http://127.0.0.1:4444/"
              },
              %{
                "name" => "DSN",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "dsn",
                    "name" => @hydra_secret
                  }
                }
              },
              %{
                "name" => "SECRETS_SYSTEM",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "secretsSystem",
                    "name" => @hydra_secret
                  }
                }
              },
              %{
                "name" => "SECRETS_COOKIE",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "secretsCookie",
                    "name" => @hydra_secret
                  }
                }
              }
            ],
            "image" => image,
            "imagePullPolicy" => "IfNotPresent",
            "lifecycle" => %{},
            "livenessProbe" => %{
              "failureThreshold" => 5,
              "httpGet" => %{
                "path" => "/health/alive",
                "port" => "http-admin"
              },
              "initialDelaySeconds" => 30,
              "periodSeconds" => 10
            },
            "name" => "hydra",
            "ports" => [
              %{
                "containerPort" => 4444,
                "name" => "http-public",
                "protocol" => "TCP"
              },
              %{
                "containerPort" => 4445,
                "name" => "http-admin",
                "protocol" => "TCP"
              }
            ],
            "readinessProbe" => %{
              "failureThreshold" => 5,
              "httpGet" => %{
                "path" => "/health/ready",
                "port" => "http-admin"
              },
              "initialDelaySeconds" => 30,
              "periodSeconds" => 10
            },
            "resources" => %{},
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{
                "drop" => [
                  "ALL"
                ]
              },
              "privileged" => false,
              "readOnlyRootFilesystem" => true,
              "runAsNonRoot" => true,
              "runAsUser" => 100
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
        "serviceAccountName" => @hyrda_service_account,
        "volumes" => [
          %{
            "configMap" => %{
              "name" => @hydra_config_map
            },
            "name" => "hydra-config-volume"
          }
        ]
      })

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app,
          "battery/component" => @hydra_component
        }
      },
      "template" => template
    }

    B.build_resource(:deployment)
    |> B.app_labels(@app)
    |> B.component_label(@hydra_component)
    |> B.name("hydra")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  @doc """
  This is the main secret, containing postgrest dsn and
  secret seeds for cookies and internal systems.
  """
  def secret_hydra(battery, state) do
    namespace = SecuritySettings.namespace(battery.config)

    B.build_resource(:secret)
    |> B.app_labels(@app)
    |> B.name(@hydra_secret)
    |> B.namespace(namespace)
    |> B.data(Secret.encode(secret_data(battery, state)))
  end

  defp secret_data(battery, state) do
    %{}
    |> Map.put("dsn", dsn(battery, state))
    |> Map.put("secretsCookie", SecuritySettings.ory_secrets_cookie(battery.config))
    |> Map.put("secretsSystem", SecuritySettings.ory_secrets_system(battery.config))
  end

  defp dsn(battery, state) do
    sec_data =
      battery |> fetch_current_secret_state(state) |> Map.get("data", %{}) |> Secret.decode!()

    db_team = RequiredDatabases.OryHydra.db_team()
    db_name = RequiredDatabases.OryHydra.db_name()

    host = "#{db_team}-#{db_name}"
    user = Map.get(sec_data, "username", "hydra")
    password = Map.get(sec_data, "password", "NOTREAL")

    "postgres://#{user}:#{password}@#{host}:5432/#{user}?sslmode=disable&max_conns=20&max_idle_conns=4"
  end

  def fetch_current_secret_state(battery, state) do
    namespace = SecuritySettings.namespace(battery.config)
    secret_name = pg_secret_name(battery, state)

    case KubeExt.KubeState.get(:secret, namespace, secret_name) do
      {:ok, res} ->
        res

      _ ->
        %{}
    end
  end

  defp pg_secret_name(_battery, _state) do
    user_name = RequiredDatabases.OryHydra.db_username()
    db_team = RequiredDatabases.OryHydra.db_team()
    db_name = RequiredDatabases.OryHydra.db_name()
    "#{user_name}.#{db_team}-#{db_name}.credentials.postgresql.acid.zalan.do"
  end

  @doc """
  Service account just for setup jobs.
  """
  def service_account_jobs(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)

    B.build_resource(:service_account)
    |> B.name(@jobs_service_account)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.component_label(@hydra_component)
  end

  @doc """
  Job to create the databases with the correct schema.

  This has to have Istio injection turned off as jobs don't
  have an init pod so there's an ordering issue and it will
  keep restarting.
  """
  def job_automigrate(battery, _state) do
    namespace = SecuritySettings.namespace(battery.config)
    image = SecuritySettings.ory_hydra_image(battery.config)

    template =
      %{}
      |> B.app_labels(@app)
      |> B.annotation("sidecar.istio.io/inject", "false")
      |> B.spec(%{
        "automountServiceAccountToken" => true,
        "containers" => [
          %{
            "args" => [
              "migrate",
              "sql",
              "-e",
              "--yes"
            ],
            "command" => [
              "hydra"
            ],
            "env" => [
              %{
                "name" => "DSN",
                "valueFrom" => %{
                  "secretKeyRef" => %{
                    "key" => "dsn",
                    "name" => @hydra_secret
                  }
                }
              }
            ],
            "image" => image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "hydra-automigrate",
            "securityContext" => %{
              "allowPrivilegeEscalation" => false
            }
          }
        ],
        "securityContext" => %{
          "runAsNonRoot" => true
        },
        "restartPolicy" => "OnFailure",
        "serviceAccountName" => @jobs_service_account,
        "shareProcessNamespace" => false
      })

    spec = %{
      "backoffLimit" => 10,
      "ttlSecondsAfterFinished" => 100,
      "template" => template
    }

    B.build_resource(:job)
    |> B.name("hydra-automigrate")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.annotation("sidecar.istio.io/inject", "false")
    |> B.spec(spec)
  end

  def materialize(battery, state) do
    %{
      "/crds" => crd(battery, state),
      "/service_account_maester" => service_account_hydra_hydra_maester_account(battery, state),
      "/service_account_hydra" => service_account_hydra(battery, state),
      "/config_map" => config_map_hydra(battery, state),
      "/cluster_role_maester" => cluster_role_hydra_hydra_maester_role(battery, state),
      "/cluster_role_binding_maester" =>
        cluster_role_binding_hydra_hydra_maester_role_binding(battery, state),
      "/role_maester" => role_hydra_hydra_maester_role_default(battery, state),
      "/role_binding_maester" =>
        role_binding_hydra_hydra_maester_role_binding_default(battery, state),
      "/service_hydra_admin" => service_hydra_admin(battery, state),
      "/service_hydra_public" => service_hydra_public(battery, state),
      "/deployment_maester" => deployment_hydra_hydra_maester(battery, state),
      "/deployment_hydra" => deployment_hydra(battery, state),
      "/secret_hydra" => secret_hydra(battery, state),
      "/service_account_jobs" => service_account_jobs(battery, state),
      "/job_automigrate" => job_automigrate(battery, state)
    }
  end
end
