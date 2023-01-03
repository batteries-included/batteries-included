defmodule KubeResources.Gitea do
  use KubeExt.IncludeResource,
    config_environment_sh: "priv/raw_files/gitea/config_environment.sh",
    configure_gitea_sh: "priv/raw_files/gitea/configure_gitea.sh",
    init_directory_structure_sh: "priv/raw_files/gitea/init_directory_structure.sh"

  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces
  import KubeExt.SystemState.Hosts

  alias KubeExt.Defaults
  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeExt.KubeState.Hosts
  alias KubeExt.Secret

  alias KubeResources.IstioConfig.VirtualService

  @app_name "gitea"

  @url_base "/x/gitea"
  @iframe_base_url "/services/devtools/gitea"

  @ssh_port 2202
  @ssh_listen_port 2022

  resource(:virtual_service, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("gitea-http")
    |> B.spec(VirtualService.rewriting(@url_base, "gitea-http"))
    |> F.require_battery(state, :istio_gateway)
  end

  resource(:ssh_virtual_service, _battery, state) do
    namespace = core_namespace(state)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("gitea-ssh")
    |> B.spec(
      VirtualService.tcp_port(@ssh_port, @ssh_listen_port, "gitea-ssh", hosts: [gitea_host(state)])
    )
    |> F.require_battery(state, :istio_gateway)
  end

  def iframe_url, do: @iframe_base_url

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: iframe_url()

  def url, do: "http://#{Hosts.control_host()}#{@url_base}" <> "/explore/repos"

  resource(:service_monitor_main, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [%{"port" => "http"}])
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "gitea"}}
      )

    B.build_resource(:monitoring_service_monitor)
    |> B.name("gitea")
    |> B.app_labels(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :prometheus)
  end

  resource(:secret_init, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("configure_gitea.sh", get_resource(:configure_gitea_sh))
      |> Map.put("init_directory_structure.sh", get_resource(:init_directory_structure_sh))
      |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("gitea-init")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  resource(:secret_inline_config, _battery, state) do
    namespace = core_namespace(state)

    http_domain = control_host(state)
    ssh_domain = gitea_host(state)

    data =
      %{}
      |> Map.put("_generals_", "")
      |> Map.put("cache", "ADAPTER=memory\nENABLED=true\nINTERVAL=60")
      |> Map.put(
        "database",
        """
        DB_TYPE=postgres
        HOST=pg-gitea.battery-core.svc.cluster.local
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
        DOMAIN=#{http_domain}
        ENABLE_PPROF=false
        HTTP_PORT=3000
        PROTOCOL=http
        ROOT_URL=http://#{http_domain}#{@url_base}
        SSH_DOMAIN=#{ssh_domain}
        SSH_LISTEN_PORT=#{@ssh_listen_port}
        SSH_PORT=#{@ssh_port}
        """
      )
      |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("gitea-inline-config")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  resource(:secret_main, _battery, state) do
    namespace = core_namespace(state)

    data =
      %{}
      |> Map.put("config_environment.sh", get_resource(:config_environment_sh))
      |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("gitea")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  resource(:service_http, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("clusterIP", "None")
      |> Map.put("ports", [%{"name" => "http", "port" => 3000, "targetPort" => 3000}])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "gitea"})
      |> Map.put("type", "ClusterIP")

    B.build_resource(:service)
    |> B.name("gitea-http")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:service_ssh, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("clusterIP", "None")
      |> Map.put("ports", [
        %{"name" => "ssh", "port" => 22, "protocol" => "TCP", "targetPort" => 22}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => "gitea"})
      |> Map.put("type", "ClusterIP")

    B.build_resource(:service)
    |> B.name("gitea-ssh")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:stateful_set_main, battery, state) do
    namespace = core_namespace(state)

    pg_secret = gitea_pg_secret_name(battery, state)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "gitea"}}
      )
      |> Map.put("serviceName", "gitea")
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => "gitea",
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
                    "valueFrom" => B.secret_key_ref(pg_secret, "username")
                  },
                  %{
                    "name" => "ENV_TO_INI__DATABASE__PASSWD",
                    "valueFrom" => B.secret_key_ref(pg_secret, "password")
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
                "env" => [
                  %{"name" => "GITEA_APP_INI", "value" => "/data/gitea/conf/app.ini"},
                  %{"name" => "GITEA_CUSTOM", "value" => "/data/gitea"},
                  %{"name" => "GITEA_WORK_DIR", "value" => "/data"},
                  %{"name" => "GITEA_TEMP", "value" => "/tmp/gitea"},
                  %{"name" => "GITEA_ADMIN_USERNAME", "value" => "gitea_admin"},
                  %{"name" => "GITEA_ADMIN_PASSWORD", "value" => "r8sA8CPHD9!bt6d"}
                ],
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
      )
      |> Map.put("volumeClaimTemplates", [
        %{
          "metadata" => %{"name" => "data"},
          "spec" => %{
            "accessModes" => ["ReadWriteOnce"],
            "resources" => %{"requests" => %{"storage" => "10Gi"}}
          }
        }
      ])

    B.build_resource(:stateful_set)
    |> B.name("gitea")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def gitea_pg_secret_name(_battery, _state) do
    user = Defaults.GiteaDB.db_username()
    team = Defaults.GiteaDB.db_team()
    cluster_name = Defaults.GiteaDB.db_name()

    "#{user}.#{team}-#{cluster_name}.credentials.postgresql.acid.zalan.do"
  end
end
