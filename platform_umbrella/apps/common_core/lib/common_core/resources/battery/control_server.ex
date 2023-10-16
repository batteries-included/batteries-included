defmodule CommonCore.Resources.ControlServer do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "battery-control-server"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Defaults
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.IstioConfig.VirtualService
  alias CommonCore.StateSummary.PostgresState

  @service_account "battery-admin"
  @server_port 4000

  resource(:virtual_service, battery, state) do
    :istio_virtual_service
    |> B.build_resource()
    |> B.namespace(core_namespace(state))
    |> B.name("control-server")
    |> B.spec(VirtualService.fallback("control-server"))
    |> F.require_battery(state, :istio_gateway)
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:service_account, battery, state) do
    :service_account
    |> B.build_resource()
    |> B.namespace(core_namespace(state))
    |> B.name("battery-admin")
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:cluster_role_binding, battery, state) do
    :cluster_role_binding
    |> B.build_resource()
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

    :service
    |> B.build_resource()
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

    :deployment
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(core_namespace(state))
    |> B.spec(spec)
    |> F.require(battery.config.server_in_cluster)
  end

  defp control_container(battery, state, options) do
    base = Keyword.get(options, :base, %{})
    name = Keyword.get(options, :name, "control-server")

    image = Keyword.get(options, :image, battery.config.image)
    cluster = PostgresState.cluster(state, name: Defaults.ControlDB.cluster_name(), type: :internal)
    user = Enum.find(cluster.users, &(&1.username == Defaults.ControlDB.user_name()))

    secret_name = PostgresState.user_secret(state, cluster, user)
    host = PostgresState.read_write_hostname(state, cluster)

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
        "value" => Defaults.ControlDB.database_name()
      },
      %{
        "name" => "SECRET_KEY_BASE",
        "value" => battery.config.secret_key
      },
      %{
        "name" => "POSTGRES_USER",
        "valueFrom" => B.secret_key_ref(secret_name, "username")
      },
      %{
        "name" => "POSTGRES_PASSWORD",
        "valueFrom" => B.secret_key_ref(secret_name, "password")
      },
      %{"name" => "MIX_ENV", "value" => "prod"}
    ])
  end
end
