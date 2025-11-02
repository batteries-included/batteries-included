defmodule CommonCore.Resources.ControlServer do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "battery-control-server"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Defaults
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.Resources.RouteBuilder, as: R
  alias CommonCore.StateSummary.Core
  alias CommonCore.StateSummary.PostgresState

  @server_port 4000
  @web_port 4001

  resource(:http_route, battery, state) do
    namespace = core_namespace(state)

    spec =
      battery
      |> R.new_httproute_spec(state)
      |> R.add_oauth2_proxy_rule(battery, state)
      |> R.add_backend(@app_name, @web_port)

    :gateway_http_route
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :istio_gateway)
    |> F.require(battery.config.usage != :internal_dev)
    |> F.require(R.valid?(spec))
  end

  resource(:service_account, battery, state) do
    :service_account
    |> B.build_resource()
    |> B.namespace(core_namespace(state))
    |> B.name(@app_name)
    |> F.require(battery.config.usage != :internal_dev)
  end

  resource(:cluster_role_binding, battery, state) do
    :cluster_role_binding
    |> B.build_resource()
    |> B.name("batteries-included:control-server-cluster-admin")
    |> Map.put("roleRef", B.build_cluster_role_ref("cluster-admin"))
    |> Map.put("subjects", [B.build_service_account(@app_name, core_namespace(state))])
    |> F.require(battery.config.usage != :internal_dev)
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
    |> F.require(battery.config.usage != :internal_dev)
  end

  resource(:stateful_set, battery, state) do
    # This name is important
    # Do not change it without also changing kube_bootstrap
    #
    # We order the control server to be created last based upon
    # this name for a  stateful set.
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
          control_container(battery, state,
            name: "init",
            base: %{
              "command" => ["/app/bin/start", "control_server_init"],
              "volumeMounts" => [%{"mountPath" => summary_dir, "name" => "summary"}]
            },
            pg_secret_name: secret_name,
            pg_host: host,
            summary_path: "#{summary_dir}/summary.json"
          )
        ],
        "containers" => [
          control_container(battery, state,
            name: name,
            base: main_container_base_args(state),
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

    :stateful_set
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(core_namespace(state))
    |> B.spec(spec)
    |> F.require(battery.config.usage != :internal_dev)
  end

  defp main_container_base_args(_state) do
    %{
      "command" => ["/app/bin/start", "control_server"],
      "ports" => [%{"containerPort" => @server_port}],
      "startupProbe" => %{
        "httpGet" => %{
          "path" => "/healthz",
          "port" => @server_port
        },
        # Try for 5 minutes to get ready
        "periodSeconds" => 5,
        "failureThreshold" => 60,
        "timeoutSeconds" => 5
      },
      # readiness and liveness won't start until after startup probe succeeds
      "readinessProbe" => %{
        "httpGet" => %{
          "path" => "/healthz",
          "port" => @server_port
        },
        "periodSeconds" => 10,
        "failureThreshold" => 5,
        "timeoutSeconds" => 3
      },
      "livenessProbe" => %{
        "httpGet" => %{
          "path" => "/healthz",
          "port" => @server_port
        },
        "periodSeconds" => 30,
        "failureThreshold" => 5,
        "timeoutSeconds" => 3
      }
    }
  end

  defp control_container(battery, state, options) do
    base = Keyword.get(options, :base, %{})
    name = Keyword.get(options, :name, "control-server")
    image = Keyword.get(options, :image, Core.controlserver_image(state))
    host = Keyword.get(options, :pg_host)
    secret_name = Keyword.get(options, :pg_secret_name)
    summary_path = Keyword.get(options, :summary_path, "")

    base
    |> Map.put_new("name", name)
    |> Map.put_new("image", image)
    |> Map.put_new("imagePullPolicy", "IfNotPresent")
    |> Map.put_new("resources", %{"requests" => %{"cpu" => "1000m", "memory" => "2000Mi"}})
    |> Map.put_new("env", [
      %{
        "name" => "LANG",
        "value" => "en_US.UTF-8"
      },
      %{
        "name" => "LC_ALL",
        "value" => "en_US.UTF-8"
      },
      %{
        "name" => "LANGUAGE",
        "value" => "en_US:en"
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
      },
      %{
        "name" => "POD_NAME",
        "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
      }
    ])
  end
end
