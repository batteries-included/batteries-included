defmodule KubeResources.Gitea do
  @moduledoc false

  use KubeExt.IncludeResource,
    app_ini_sh: "priv/raw_files/gitea/app_ini.sh",
    init_directory_structure_sh: "priv/raw_files/gitea/init_directory_structure.sh",
    configure_gitea_sh: "priv/raw_files/gitea/configure_gitea.sh"

  alias KubeExt.Builder, as: B
  alias KubeResources.DevtoolsSettings
  alias KubeResources.IstioConfig.VirtualService
  alias KubeExt.KubeState.Hosts

  @app "gitea"

  @data_path "/data"
  @init_path "/opt/sbin"
  @tmp_path "/tmp"

  @url_base "/x/gitea"
  @iframe_base_url "/services/devtools/gitea"

  @ssh_port 22
  @ssh_listen_port 2022

  def virtual_service(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("gitea-http")
    |> B.spec(VirtualService.rewriting(@url_base, "gitea-http"))
  end

  def ssh_virtual_service(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("gitea-ssh")
    |> B.spec(
      VirtualService.tcp_port(@ssh_port, @ssh_listen_port, "gitea-ssh",
        hosts: [Hosts.gitea_host()]
      )
    )
  end

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: iframe_url()

  def url, do: "//#{Hosts.control_host()}#{@url_base}" <> "/explore/repos"

  def iframe_url, do: @iframe_base_url

  def secret(config) do
    namespace = DevtoolsSettings.namespace(config)

    http_domain = Hosts.control_host()
    ssh_domain = Hosts.gitea_host()

    data = %{
      "_generals_" => "",
      "cache" => """
      ADAPTER=memory
      ENABLED=true
      INTERVAL=60
      """,
      "database" => """
      DB_TYPE=postgres
      HOST=pg-gitea.battery-core.svc.cluster.local
      NAME=gitea
      PASSWD=gitea
      USER=root
      SSL_MODE=require
      """,
      "metrics" => "ENABLED=true",
      "repository" => "ROOT=#{@data_path}/git/gitea-repositories",
      "security" => "INSTALL_LOCK=true",
      "server" => """
      APP_DATA_PATH=#{@data_path}
      DOMAIN=#{http_domain}
      ENABLE_PPROF=false
      HTTP_PORT=3000
      PROTOCOL=http
      ROOT_URL=http://#{http_domain}#{@url_base}
      SSH_DOMAIN=#{ssh_domain}
      SSH_LISTEN_PORT=#{@ssh_port}
      SSH_PORT=#{@ssh_port}
      """
    }

    B.build_resource(:secret)
    |> B.name("gitea-inline-config")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> Map.put("stringData", data)
  end

  def secret_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "app_ini.sh" => get_resource(:app_ini_sh),
      "init_directory_structure.sh" => get_resource(:init_directory_structure_sh),
      "configure_gitea.sh" => get_resource(:configure_gitea_sh)
    }

    B.build_resource(:secret)
    |> B.name("gitea-init")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> Map.put("stringData", data)
  end

  def service(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec =
      %{}
      |> B.short_selector(@app)
      |> B.ports([
        %{"targetPort" => 3000, "port" => 3000, "name" => "http"}
      ])

    B.build_resource(:service)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name("gitea-http")
    |> B.spec(spec)
  end

  def service_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec =
      %{}
      |> B.short_selector(@app)
      |> B.ports([
        %{
          "targetPort" => @ssh_listen_port,
          "port" => @ssh_listen_port,
          "protocol" => "TCP",
          "name" => "ssh"
        }
      ])

    B.build_resource(:service)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name("gitea-ssh")
    |> B.spec(spec)
  end

  defp add_command(container, nil = _command), do: container
  defp add_command(container, command), do: Map.put(container, "command", [command])

  defp base_container(config, name, command \\ nil) do
    gitea_image = DevtoolsSettings.gitea_image(config)

    pg_secret = DevtoolsSettings.gitea_pg_secret_name(config)

    %{}
    |> Map.put("name", name)
    |> Map.put("image", gitea_image)
    |> Map.put("env", [
      %{"name" => "GITEA_CUSTOM", "value" => Path.join(@data_path, "/gitea")},
      %{"name" => "GITEA_APP_INI", "value" => Path.join(@data_path, "/gitea/conf/app.ini")},
      %{"name" => "GITEA_WORK_DIR", "value" => @data_path},
      %{"name" => "SSH_LISTEN_PORT", "value" => "#{@ssh_listen_port}"},
      %{"name" => "SSH_PORT", "value" => "#{@ssh_port}"},
      %{"name" => "GITEA_TEMP", "value" => Path.join(@tmp_path, "/gitea")},
      %{"name" => "TMPDIR", "value" => Path.join(@tmp_path, "/gitea")},
      %{
        "name" => "ENV_TO_INI__DATABASE__USER",
        "valueFrom" => B.secret_key_ref(pg_secret, "username")
      },
      %{
        "name" => "ENV_TO_INI__DATABASE__PASSWD",
        "valueFrom" => B.secret_key_ref(pg_secret, "password")
      },

      # TODO Clean this up!
      %{"name" => "GITEA_ADMIN_USERNAME", "value" => "gitea_admin"},
      %{"name" => "GITEA_ADMIN_PASSWORD", "value" => "r8sA8CPHD9!bt6d"}
    ])
    |> Map.put("volumeMounts", [
      %{"name" => "init", "mountPath" => @init_path},
      %{"name" => "temp", "mountPath" => "/tmp"},
      %{"name" => "data", "mountPath" => @data_path},
      %{
        "name" => "inline-config-sources",
        "mountPath" => "/env-to-ini-mounts/inlines/"
      }
    ])
    |> add_command(command)
  end

  defp main_container(config) do
    config
    |> base_container("gitea")
    |> Map.put("ports", [
      %{"name" => "ssh", "containerPort" => @ssh_listen_port},
      %{"name" => "http", "containerPort" => 3000}
    ])
    |> Map.put("livenessProbe", %{
      "failureThreshold" => 10,
      "initialDelaySeconds" => 200,
      "periodSeconds" => 10,
      "successThreshold" => 1,
      "tcpSocket" => %{"port" => "http"},
      "timeoutSeconds" => 1
    })
    |> Map.put("readinessProbe", %{
      "failureThreshold" => 3,
      "initialDelaySeconds" => 5,
      "periodSeconds" => 10,
      "successThreshold" => 1,
      "tcpSocket" => %{"port" => "http"},
      "timeoutSeconds" => 1
    })
  end

  def stateful_set(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app}
      },
      "serviceName" => "gitea",
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "gitea",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "securityContext" => %{"fsGroup" => 1000},
          "initContainers" => [
            # This one creates and chowns all the dirs needed
            base_container(
              config,
              "init-directories",
              "/opt/sbin/init_directory_structure.sh"
            ),
            # This one creates the ini
            base_container(config, "init-app-ini", "/opt/sbin/app_ini.sh"),

            # This migrates the database
            # It fails if run as root.
            config
            |> base_container("configure-gitea", "/opt/sbin/configure_gitea.sh")
            |> Map.put("securityContext", %{"runAsUser" => 1000})
          ],
          "terminationGracePeriodSeconds" => 60,
          "containers" => [
            main_container(config)
          ],
          "volumes" => [
            %{
              "name" => "init",
              "secret" => %{"secretName" => "gitea-init", "defaultMode" => 110}
            },
            %{"name" => "config", "secret" => %{"secretName" => "gitea", "defaultMode" => 110}},
            %{
              "name" => "inline-config-sources",
              "secret" => %{"secretName" => "gitea-inline-config"}
            },
            %{"name" => "temp", "emptyDir" => %{}}
          ]
        }
      },
      "volumeClaimTemplates" => [
        %{
          "metadata" => %{"name" => "data"},
          "spec" => %{
            "accessModes" => ["ReadWriteOnce"],
            "resources" => %{"requests" => %{"storage" => "10Gi"}}
          }
        }
      ]
    }

    B.build_resource(:stateful_set)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("gitea")
    |> B.spec(spec)
  end

  def materialize(config) do
    %{
      "/0/secret" => secret(config),
      "/1/secret_1" => secret_1(config),
      "/3/service" => service(config),
      "/4/service_1" => service_1(config),
      "/5/stateful_set" => stateful_set(config)
    }
  end
end
