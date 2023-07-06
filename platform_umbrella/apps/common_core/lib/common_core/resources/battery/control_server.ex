defmodule CommonCore.Resources.ControlServer do
  import CommonCore.StateSummary.Namespaces
  use CommonCore.Resources.ResourceGenerator, app_name: "battery-control-server"

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.IstioConfig.VirtualService
  alias CommonCore.Defaults

  @service_account "battery-admin"
  @server_port 4000

  resource(:virtual_service, battery, state) do
    B.build_resource(:istio_virtual_service)
    |> B.namespace(core_namespace(state))
    |> B.name("control-server")
    |> B.spec(VirtualService.fallback("control-server"))
    |> F.require_battery(state, :istio_gateway)
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:service_account, battery, state) do
    B.build_resource(:service_account)
    |> B.namespace(core_namespace(state))
    |> B.name("battery-admin")
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:cluster_role_binding, battery, state) do
    B.build_resource(:cluster_role_binding)
    |> B.name("battery-admin-cluster-admin")
    |> Map.put(
      "roleRef",
      B.build_cluster_role_ref("cluster-admin")
    )
    |> Map.put("subjects", [
      B.build_service_account("battery-admin", core_namespace(state))
    ])
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:service, battery, state) do
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
    |> B.name("control-server")
    |> B.namespace(core_namespace(state))
    |> B.spec(spec)
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:deployment, battery, state) do
    name = "controlserver"

    template = %{
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "true"
        }
      },
      "spec" => %{
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
      }
    }

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> B.match_labels_selector(@app_name)
      |> B.template(template)

    B.build_resource(:deployment)
    |> B.name(name)
    |> B.namespace(core_namespace(state))
    |> B.spec(spec)
    |> F.require(battery.config.server_in_cluster)
  end

  defp control_container(battery, state, options) do
    base = Keyword.get(options, :base, %{})
    name = Keyword.get(options, :name, "control-server")

    image = Keyword.get(options, :image, battery.config.image)

    host = pg_host(battery, state)
    db = pg_db_name(battery, state)
    credential_secret = pg_secret(battery, state)

    base
    |> Map.put_new("name", name)
    |> Map.put_new("image", image)
    |> Map.put_new("resources", %{
      "limits" => %{"memory" => "500Mi"},
      "requests" => %{"cpu" => "200m", "memory" => "300Mi"}
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
        "value" => battery.config.secret_key
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

  defp pg_host(_battery, state) do
    pg_cluster = Defaults.ControlDB.control_cluster()
    ns = core_namespace(state)
    "#{pg_cluster.team_name}-#{pg_cluster.name}.#{ns}.svc"
  end

  defp pg_secret(_battery, _state) do
    pg_cluster = Defaults.ControlDB.control_cluster()
    owner = pg_first_database().owner

    "#{owner}.#{pg_cluster.name}.credentials.postgresql"
  end

  defp pg_db_name(_battery, _state) do
    pg_first_database().name
  end

  defp pg_first_database do
    Defaults.ControlDB.control_cluster()
    |> Map.get(:databases, [])
    |> List.first(%{name: "control", owner: "controlserver"})
  end
end
