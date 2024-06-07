defmodule CommonCore.Resources.ControlServer do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "battery-control-server"

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Defaults
  alias CommonCore.OpenAPI.IstioVirtualService.VirtualService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.VirtualServiceBuilder, as: V
  alias CommonCore.StateSummary.PostgresState

  @server_port 4000
  @web_port 4001

  resource(:virtual_service, battery, state) do
    spec =
      [hosts: [control_host(state)]]
      |> VirtualService.new!()
      |> V.fallback(@app_name, @web_port)

    :istio_virtual_service
    |> B.build_resource()
    |> B.namespace(core_namespace(state))
    |> B.name("control-server")
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:service_account, battery, state) do
    :service_account
    |> B.build_resource()
    |> B.namespace(core_namespace(state))
    |> B.name(@app_name)
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:cluster_role_binding, battery, state) do
    :cluster_role_binding
    |> B.build_resource()
    |> B.name("batteries-included:control-server-cluster-admin")
    |> Map.put("roleRef", B.build_cluster_role_ref("cluster-admin"))
    |> Map.put("subjects", [B.build_service_account(@app_name, core_namespace(state))])
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:service, battery, state) do
    spec =
      %{}
      |> B.short_selector(@app_name)
      |> B.ports([
        %{
          "targetPort" => @server_port,
          "port" => @web_port,
          "protocol" => "TCP",
          "name" => "http"
        }
      ])

    :service
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(core_namespace(state))
    |> B.spec(spec)
    |> F.require(battery.config.server_in_cluster)
  end

  resource(:deployment, battery, state) do
    name = "controlserver"

    cluster = PostgresState.cluster(state, name: Defaults.ControlDB.cluster_name(), type: :internal)
    user = Enum.find(cluster.users, &(&1.username == Defaults.ControlDB.user_name()))
    secret_name = PostgresState.user_secret(state, cluster, user)
    host = PostgresState.read_write_hostname(state, cluster)
    summary_dir = "/var/run/secrets/summary"

    template = %{
      "metadata" => %{
        "labels" => %{
          "battery/app" => @app_name,
          "battery/managed" => "true"
        }
      },
      "spec" => %{
        "automountServiceAccountToken" => true,
        "serviceAccount" => @app_name,
        "serviceAccountName" => @app_name,
        "initContainers" => [
          control_container(battery,
            name: "init",
            base: %{
              "command" => ["control_server_init"],
              "volumeMounts" => [%{"mountPath" => summary_dir, "name" => "summary"}]
            },
            pg_secret_name: secret_name,
            pg_host: host,
            summary_path: "#{summary_dir}/summary.json"
          )
        ],
        "containers" => [
          control_container(battery,
            name: name,
            base: %{
              "command" => ["control_server", "start"],
              "ports" => [%{"containerPort" => @server_port}]
            },
            pg_secret_name: secret_name,
            pg_host: host
          )
        ],
        "volumes" => [
          %{
            "name" => "summary",
            "secret" => %{"defaultMode" => 420, "optional" => true, "secretName" => "initial-target-summary"}
          }
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

  defp control_container(battery, options) do
    base = Keyword.get(options, :base, %{})
    name = Keyword.get(options, :name, "control-server")
    image = Keyword.get(options, :image, battery.config.image)
    host = Keyword.get(options, :pg_host)
    secret_name = Keyword.get(options, :pg_secret_name)
    summary_path = Keyword.get(options, :summary_path, "")

    base
    |> Map.put_new("name", name)
    |> Map.put_new("image", image)
    |> Map.put_new("imagePullPolicy", "Always")
    |> Map.put_new("resources", %{"requests" => %{"cpu" => "1000m", "memory" => "2000Mi"}})
    |> Map.put_new("env", [
      %{
        "name" => "LC_CTYPE",
        "value" => "en_US.UTF-8"
      },
      %{
        "name" => "LANG",
        "value" => "en_US.UTF-8"
      },
      %{
        "name" => "LC_ALL",
        "value" => "en_US.UTF-8"
      },
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
        "name" => "RELEASE_COOKIE",
        "value" => battery.config.secret_key
      },
      %{
        "name" => "BOOTSTRAP_SUMMARY_PATH",
        "value" => summary_path
      },
      %{
        "name" => "POSTGRES_USER",
        "valueFrom" => B.secret_key_ref(secret_name, "username")
      },
      %{
        "name" => "POSTGRES_PASSWORD",
        "valueFrom" => B.secret_key_ref(secret_name, "password")
      }
    ])
  end

  resource(:info_configmap, _battery, state) do
    host = control_host(state)
    data = %{"hostname" => host}

    :config_map
    |> B.build_resource()
    |> B.name("control-server-info")
    |> B.namespace(core_namespace(state))
    |> B.data(data)
    |> F.require(valid_host?(host))
  end

  defp valid_host?(host) do
    host != nil and
      String.length(host) > 0 and
      !String.contains?(host, "..ip.batteriesincl.com") and
      valid_uri?(host)
  end

  # assume for now that, if it's parseable, that's good enough
  defp valid_uri?(host) do
    case URI.new(host) do
      {:ok, _uri} -> true
      _ -> false
    end
  end
end
