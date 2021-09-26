defmodule KubeResources.ControlServer do
  alias KubeResources.BatterySettings

  alias KubeExt.Builder, as: B

  @app_name "control-server"
  @service_account "battery-admin"
  @server_port 4000

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
            name: "migrate",
            base: %{"command" => ["bin/control_server_migrate"]}
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
    version = Keyword.get(options, :version, BatterySettings.control_server_version(config))
    image = Keyword.get(options, :image, BatterySettings.control_server_image(config))

    base
    |> Map.put_new("name", name)
    |> Map.put_new("image", "#{image}:#{version}")
    |> Map.put_new("resources", %{
      "limits" => %{"cpu" => "200m", "memory" => "200Mi"},
      "requests" => %{"cpu" => "200m", "memory" => "200Mi"}
    })
    |> Map.put_new("env", [
      %{
        "name" => "PORT",
        "value" => "#{@server_port}"
      },
      %{
        "name" => "POSTGRES_HOST",
        "value" => "postgres.default.svc.cluster.local"
      },
      %{
        "name" => "POSTGRES_DB",
        "value" => "control-dev"
      },
      %{
        "name" => "SECRET_KEY_BASE",
        "value" => "Pmor7rzJc4IDaplYh1CU92+yEEl9IueDvNQrfFjl8QQtcTgjgfBX0wPDpPfz9fen"
      },
      %{
        "name" => "POSTGRES_USER",
        "value" => "batterydbuser"
      },
      %{
        "name" => "POSTGRES_PASSWORD",
        "value" => "batterypasswd"
      },
      %{"name" => "MIX_ENV", "value" => "prod"}
    ])
  end

  def service(%{"control.run" => true} = config) do
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

  def ingress(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:ingress, "/", "control-server", "http")
    |> B.name("control-server")
    |> B.annotation("nginx.org/websocket-services", "control-server")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def virtual_service(config) do
    namespace = BatterySettings.namespace(config)

    spec = %{
      gateways: ["battery-gateway"],
      hosts: ["*"],
      http: [
        %{
          route: [
            %{destination: %{port: %{number: 8080}, host: "control-server"}}
          ]
        }
      ]
    }

    B.build_resource(:virtual_service)
    |> B.name("control-server")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end
end
