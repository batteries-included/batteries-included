defmodule KubeResources.ControlServer do
  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F
  alias KubeResources.IstioConfig.VirtualService
  alias KubeExt.Defaults

  @app_name "control-server"
  @service_account "battery-admin"
  @server_port 4000

  def materialize(battery, state) do
    %{
      "/deployment" => deployment(battery, state),
      "/service" => service(battery, state),
      "/service_account" => service_account(battery, state),
      "/cluster_role_binding" => cluster_role_binding(battery, state),
      "/virtual_service" => virtual_service(battery, state)
    }
  end

  def virtual_service(_battery, state) do
    B.build_resource(:istio_virtual_service)
    |> B.namespace(core_namespace(state))
    |> B.app_labels(@app_name)
    |> B.name("control-server")
    |> B.spec(VirtualService.fallback("control-server"))
    |> F.require_battery(state, :istio_gateway)
  end

  def service_account(_battery, state) do
    B.build_resource(:service_account)
    |> B.namespace(core_namespace(state))
    |> B.name("battery-admin")
    |> B.app_labels(@app_name)
  end

  def cluster_role_binding(_battery, state) do
    B.build_resource(:cluster_role_binding)
    |> B.name("battery-admin-cluster-admin")
    |> B.app_labels(@app_name)
    |> Map.put(
      "roleRef",
      B.build_cluster_role_ref("cluster-admin")
    )
    |> Map.put("subjects", [
      B.build_service_account("battery-admin", core_namespace(state))
    ])
  end

  def deployment(battery, state) do
    name = "controlserver"

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
    |> B.namespace(core_namespace(state))
    |> B.app_labels(@app_name)
    |> B.spec(spec)
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
    "#{pg_cluster.team_name}-#{pg_cluster.name}.#{ns}.svc.cluster.local"
  end

  defp pg_secret(_battery, _state) do
    pg_cluster = Defaults.ControlDB.control_cluster()
    owner = pg_first_database().owner

    "#{owner}.#{pg_cluster.name}.credentials.postgresql.acid.zalan.do"
  end

  defp pg_db_name(_battery, _state) do
    pg_first_database().name
  end

  defp pg_first_database do
    Defaults.ControlDB.control_cluster()
    |> Map.get(:databases, [])
    |> List.first(%{name: "control", owner: "controlserver"})
  end

  def service(_battery, state) do
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
    |> B.namespace(core_namespace(state))
    |> B.spec(spec)
  end
end
