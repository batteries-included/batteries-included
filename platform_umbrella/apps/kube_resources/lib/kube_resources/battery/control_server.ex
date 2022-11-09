defmodule KubeResources.ControlServer do
  alias KubeExt.Builder, as: B
  alias KubeResources.BatterySettings
  alias KubeResources.IstioConfig.VirtualService

  @app_name "control-server"
  @service_account "battery-admin"
  @server_port 4000

  def materialize(battery, state) do
    %{
      "/deployment" => deployment(battery, state),
      "/service" => service(battery, state)
    }
  end

  def virtual_service(battery, _state) do
    namespace = BatterySettings.namespace(battery.config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("control-server")
    |> B.spec(VirtualService.fallback("control-server"))
  end

  def deployment(battery, state) do
    namespace = BatterySettings.namespace(battery.config)
    name = BatterySettings.control_server_name(battery.config)

    template =
      %{}
      |> B.app_labels(@app_name)
      |> B.spec(%{
        "serviceAccount" => @service_account,
        "initContainers" => [
          control_container(battery, state,
            name: "init",
            base: %{"command" => ["bin/control_server_init"]}
          )
        ],
        "containers" => [
          control_container(battery, state,
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

  defp control_container(battery, _state, options) do
    base = Keyword.get(options, :base, %{})
    name = Keyword.get(options, :name, "control-server")

    image = Keyword.get(options, :image, BatterySettings.control_server_image(battery.config))

    host = BatterySettings.control_server_pg_host(battery.config)
    db = BatterySettings.control_server_pg_db(battery.config)
    credential_secret = BatterySettings.control_server_pg_secret(battery.config)

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

  def service(battery, _state) do
    namespace = BatterySettings.namespace(battery.config)

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
