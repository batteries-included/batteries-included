defmodule KubeRawResources.ControlServerResources do
  alias KubeRawResources.BatterySettings

  alias KubeExt.Builder, as: B

  @app_name "control-server"
  @service_account "battery-admin"
  @server_port 4000

  def materialize(config) do
    %{
      "/deployment" => deployment(config),
      "/service" => service(config)
    }
  end

  def deployment(config) do
    # def deployment(config) do
    namespace = BatterySettings.namespace(config)
    name = BatterySettings.control_server_name(config)

    template =
      %{}
      |> B.app_labels(@app_name)
      |> B.spec(%{
        "serviceAccount" => @service_account,
        "initContainers" => [
          control_container(config,
            name: "init",
            base: %{"command" => ["bin/control_server_init"]}
          )
        ],
        "containers" => [
          control_container(config,
            name: name,
            base: %{
              "command" => ["bin/control_server", "start"],
              "ports" => [%{"containerPort" => @server_port}]
            }
          )
        ]
      })

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> B.match_labels_selector(@app_name)
      |> B.template(template)

    B.build_resource(:deployment)
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  defp control_container(config, options) do
    base = Keyword.get(options, :base, %{})
    name = Keyword.get(options, :name, "control-server")

    image = Keyword.get(options, :image, BatterySettings.control_server_image(config))

    host = BatterySettings.control_server_pg_host(config)
    db = BatterySettings.control_server_pg_db(config)
    credential_secret = BatterySettings.control_server_pg_secret(config)

    base
    |> Map.put_new("name", name)
    |> Map.put_new("image", image)
    |> Map.put_new("resources", %{
      "limits" => %{"memory" => "200Mi"},
      "requests" => %{"cpu" => "200m", "memory" => "200Mi"}
    })
    |> Map.put_new("env", [
      %{
        "name" => "PORT",
        "value" => "#{@server_port}"
      },
      %{
        "name" => "POSTGRES_HOST",
        "value" => host
      },
      %{
        "name" => "POSTGRES_DB",
        "value" => db
      },
      %{
        "name" => "SECRET_KEY_BASE",
        "value" => "Pmor7rzJc4IDaplYh1CU92+yEEl9IueDvNQrfFjl8QQtcTgjgfBX0wPDpPfz9fen"
      },
      %{
        "name" => "POSTGRES_USER",
        "valueFrom" => B.secret_key_ref(credential_secret, "username")
      },
      %{
        "name" => "POSTGRES_PASSWORD",
        "valueFrom" => B.secret_key_ref(credential_secret, "password")
      },
      %{"name" => "MIX_ENV", "value" => "prod"}
    ])
  end

  def service(config) do
    namespace = BatterySettings.namespace(config)

    spec =
      %{}
      |> B.short_selector(@app_name)
      |> B.ports([
        %{
          "targetPort" => @server_port,
          "port" => @server_port,
          "protocol" => "TCP",
          "name" => "http"
        }
      ])

    B.build_resource(:service)
    |> B.app_labels(@app_name)
    |> B.name("control-server")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end
end
