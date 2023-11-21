defmodule CommonCore.Resources.Gitea do
  @moduledoc false

  use CommonCore.IncludeResource,
    config_environment_sh: "priv/raw_files/gitea/config_environment.sh",
    configure_gitea_sh: "priv/raw_files/gitea/configure_gitea.sh",
    init_directory_structure_sh: "priv/raw_files/gitea/init_directory_structure.sh"

  use CommonCore.Resources.ResourceGenerator, app_name: "gitea"

  import CommonCore.Resources.MapUtils
  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Defaults
  alias CommonCore.OpenApi.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.Secret
  alias CommonCore.Resources.VirtualServiceBuilder, as: V
  alias CommonCore.StateSummary.PostgresState

  @ssh_port 2202
  @ssh_listen_port 2022
  @http_listen_port 3000

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    spec =
      [hosts: [gitea_host(state)]]
      |> VirtualService.new!()
      |> V.fallback("gitea-http", @http_listen_port)
      |> V.tcp(@ssh_port, "gitea-ssh", @ssh_listen_port)

    :istio_virtual_service
    |> B.build_resource()
    |> B.namespace(namespace)
    |> B.name("gitea")
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:service_monitor_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"port" => "http"}])
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name}}
      )

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("gitea")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:secret_init, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("configure_gitea.sh", get_resource(:configure_gitea_sh))
      |> Map.put("init_directory_structure.sh", get_resource(:init_directory_structure_sh))
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("gitea-init")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_inline_config, _battery, state) do
    namespace = core_namespace(state)
    namespace_base = base_namespace(state)

    domain = gitea_host(state)

    sso_enabled? = F.sso_installed?(state)

    data =
      %{}
      |> Map.put("_generals_", "")
      |> Map.put("cache", "ADAPTER=memory\nENABLED=true\nINTERVAL=60")
      |> Map.put(
        "database",
        """
        DB_TYPE=postgres
        HOST=pg-gitea.#{namespace_base}.svc.cluster.local.
        NAME=gitea
        USER=root
        PASSWD=gitea
        SCHEMA=public
        SSL_MODE=require
        """
      )
      |> Map.put("metrics", "ENABLED=true")
      |> Map.put("repository", "ROOT=/data/git/gitea-repositories")
      |> Map.put("security", "INSTALL_LOCK=true")
      |> Map.put(
        "server",
        """
        APP_DATA_PATH=/data
        DOMAIN=#{domain}
        ENABLE_PPROF=false
        HTTP_PORT=#{@http_listen_port}
        PROTOCOL=http
        ROOT_URL=http://#{domain}
        SSH_DOMAIN=#{domain}
        SSH_LISTEN_PORT=#{@ssh_listen_port}
        SSH_PORT=#{@ssh_port}
        DISABLE_REGISTRATION=#{sso_enabled?}
        SHOW_REGISTRATION_BUTTON=#{!sso_enabled?}
        ALLOW_ONLY_EXTERNAL_REGISTRATION=#{sso_enabled?}
        """
      )
      |> maybe_put(
        sso_enabled?,
        "openid",
        """
        ENABLE_OPENID_SIGNIN=true
        ENABLE_OPENID_SIGNUP=true
        """
      )
      |> maybe_put(
        sso_enabled?,
        "oauth2_client",
        """
        OPENID_CONNECT_SCOPES=openid email profile offline_access roles
        ENABLE_AUTO_REGISTRATION=true
        USERNAME=email
        """
      )
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("gitea-inline-config")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:secret_main, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("config_environment.sh", get_resource(:config_environment_sh))
      |> Secret.encode()

    :secret
    |> B.build_resource()
    |> B.name("gitea")
    |> B.namespace(namespace)
    |> B.data(data)
  end

  resource(:service_http, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "http", "port" => @http_listen_port, "targetPort" => @http_listen_port}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("gitea-http")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_ssh, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{
          "name" => "ssh",
          "port" => @ssh_port,
          "protocol" => "TCP",
          "targetPort" => @ssh_listen_port
        }
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("gitea-ssh")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:stateful_set_main, battery, state) do
    namespace = core_namespace(state)
    cluster = PostgresState.cluster(state, name: Defaults.GiteaDB.cluster_name(), type: :internal)
    user = Enum.find(cluster.users, fn user -> user.username == Defaults.GiteaDB.db_username() end)
    secret_name = PostgresState.user_secret(state, cluster, user)

    sso_enabled? = F.sso_installed?(state)

    template = %{
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "containers" => [
          %{
            "env" => [
              %{"name" => "SSH_LISTEN_PORT", "value" => to_string(@ssh_listen_port)},
              %{"name" => "SSH_PORT", "value" => to_string(@ssh_port)},
              %{"name" => "GITEA_APP_INI", "value" => "/data/gitea/conf/app.ini"},
              %{"name" => "GITEA_CUSTOM", "value" => "/data/gitea"},
              %{"name" => "GITEA_WORK_DIR", "value" => "/data"},
              %{"name" => "GITEA_TEMP", "value" => "/tmp/gitea"},
              %{"name" => "TMPDIR", "value" => "/tmp/gitea"}
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "Always",
            "livenessProbe" => %{
              "failureThreshold" => 10,
              "initialDelaySeconds" => 200,
              "periodSeconds" => 10,
              "successThreshold" => 1,
              "tcpSocket" => %{"port" => "http"},
              "timeoutSeconds" => 1
            },
            "name" => "gitea",
            "ports" => [
              %{"containerPort" => 22, "name" => "ssh"},
              %{"containerPort" => 3000, "name" => "http"}
            ],
            "readinessProbe" => %{
              "failureThreshold" => 3,
              "initialDelaySeconds" => 5,
              "periodSeconds" => 10,
              "successThreshold" => 1,
              "tcpSocket" => %{"port" => "http"},
              "timeoutSeconds" => 1
            },
            "resources" => %{},
            "securityContext" => %{},
            "volumeMounts" => [
              %{"mountPath" => "/tmp", "name" => "temp"},
              %{"mountPath" => "/data", "name" => "data"}
            ]
          }
        ],
        "initContainers" => [
          %{
            "command" => ["/usr/sbin/init_directory_structure.sh"],
            "env" => [
              %{"name" => "GITEA_APP_INI", "value" => "/data/gitea/conf/app.ini"},
              %{"name" => "GITEA_CUSTOM", "value" => "/data/gitea"},
              %{"name" => "GITEA_WORK_DIR", "value" => "/data"},
              %{"name" => "GITEA_TEMP", "value" => "/tmp/gitea"}
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "Always",
            "name" => "init-directories",
            "securityContext" => %{},
            "volumeMounts" => [
              %{"mountPath" => "/usr/sbin", "name" => "init"},
              %{"mountPath" => "/tmp", "name" => "temp"},
              %{"mountPath" => "/data", "name" => "data"}
            ]
          },
          %{
            "command" => ["/usr/sbin/config_environment.sh"],
            "env" => [
              %{"name" => "GITEA_APP_INI", "value" => "/data/gitea/conf/app.ini"},
              %{"name" => "GITEA_CUSTOM", "value" => "/data/gitea"},
              %{"name" => "GITEA_WORK_DIR", "value" => "/data"},
              %{"name" => "GITEA_TEMP", "value" => "/tmp/gitea"},
              %{
                "name" => "ENV_TO_INI__DATABASE__USER",
                "valueFrom" => B.secret_key_ref(secret_name, "username")
              },
              %{
                "name" => "ENV_TO_INI__DATABASE__PASSWD",
                "valueFrom" => B.secret_key_ref(secret_name, "password")
              },
              %{
                "name" => "ENV_TO_INI__DATABASE__HOST",
                "valueFrom" => B.secret_key_ref(secret_name, "hostname")
              }
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "Always",
            "name" => "init-app-ini",
            "securityContext" => %{},
            "volumeMounts" => [
              %{"mountPath" => "/usr/sbin", "name" => "config"},
              %{"mountPath" => "/tmp", "name" => "temp"},
              %{"mountPath" => "/data", "name" => "data"},
              %{
                "mountPath" => "/env-to-ini-mounts/inlines/",
                "name" => "inline-config-sources"
              }
            ]
          },
          %{
            "command" => ["/usr/sbin/configure_gitea.sh"],
            "env" =>
              [
                %{"name" => "GITEA_APP_INI", "value" => "/data/gitea/conf/app.ini"},
                %{"name" => "GITEA_CUSTOM", "value" => "/data/gitea"},
                %{"name" => "GITEA_WORK_DIR", "value" => "/data"},
                %{"name" => "GITEA_TEMP", "value" => "/tmp/gitea"},
                %{"name" => "GITEA_ADMIN_USERNAME", "value" => battery.config.admin_username},
                %{"name" => "GITEA_ADMIN_PASSWORD", "value" => battery.config.admin_password}
              ] ++
                if sso_enabled? do
                  case CommonCore.StateSummary.KeycloakSummary.client(
                         state.keycloak_state,
                         app_name()
                       ) do
                    %{realm: realm, client: %{clientId: client_id, secret: client_secret}} ->
                      keycloak_autodiscover_url =
                        "http://#{keycloak_host(state)}/realms/#{realm}/.well-known/openid-configuration"

                      [
                        %{"name" => "OAUTH_NAME", "value" => "keycloak"},
                        %{"name" => "AUTODISCOVER_URL", "value" => keycloak_autodiscover_url},
                        %{"name" => "CLIENT_ID", "value" => client_id},
                        %{"name" => "CLIENT_SECRET", "value" => client_secret}
                      ]

                    nil ->
                      []
                  end
                else
                  []
                end,
            "image" => battery.config.image,
            "imagePullPolicy" => "Always",
            "name" => "configure-gitea",
            "securityContext" => %{"runAsUser" => 1000},
            "volumeMounts" => [
              %{"mountPath" => "/usr/sbin", "name" => "init"},
              %{"mountPath" => "/tmp", "name" => "temp"},
              %{"mountPath" => "/data", "name" => "data"}
            ]
          }
        ],
        "securityContext" => %{"fsGroup" => 1000},
        "terminationGracePeriodSeconds" => 60,
        "volumes" => [
          %{
            "name" => "init",
            "secret" => %{"defaultMode" => 110, "secretName" => "gitea-init"}
          },
          %{"name" => "config", "secret" => %{"defaultMode" => 110, "secretName" => "gitea"}},
          %{
            "name" => "inline-config-sources",
            "secret" => %{"secretName" => "gitea-inline-config"}
          },
          %{"emptyDir" => %{}, "name" => "temp"}
        ]
      }
    }

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> Map.put("serviceName", "gitea")
      |> Map.put("template", template)
      |> Map.put("volumeClaimTemplates", [
        %{
          "metadata" => %{"name" => "data"},
          "spec" => %{
            "accessModes" => ["ReadWriteOnce"],
            "resources" => %{"requests" => %{"storage" => "10Gi"}}
          }
        }
      ])

    :stateful_set
    |> B.build_resource()
    |> B.name("gitea")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end
end
