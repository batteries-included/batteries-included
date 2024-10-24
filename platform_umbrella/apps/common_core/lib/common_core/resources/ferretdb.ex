defmodule CommonCore.Resources.FerretDB do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "ferretdb"

  import CommonCore.Resources.MapUtils
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.FerretDB.FerretService
  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary

  multi_resource(:deployments, battery, %StateSummary{} = state) do
    Enum.map(state.ferret_services, fn ferret_service -> deployment(ferret_service, battery, state) end)
  end

  multi_resource(:services, battery, %StateSummary{} = state) do
    Enum.map(state.ferret_services, fn ferret_service -> service(ferret_service, battery, state) end)
  end

  multi_resource(:service_accounts, battery, %StateSummary{} = state) do
    Enum.map(state.ferret_services, fn ferret_service -> service_account(ferret_service, battery, state) end)
  end

  resource(:monitoring_pod_monitor, _battery, state) do
    namespace = data_namespace(state)

    spec =
      %{}
      |> Map.put("podMetricsEndpoints", [%{"path" => "/metrics", "port" => "debug"}])
      |> Map.put("selector", %{"matchLabels" => %{"battery/component" => @app_name}})

    :monitoring_pod_monitor
    |> B.build_resource()
    |> B.name("ferretdb-monitoring")
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
    |> F.require_non_empty(state.ferret_services)
  end

  def service_account(%FerretService{} = ferret_service, _battery, %StateSummary{} = state) do
    :service_account
    |> B.build_resource()
    |> B.name(service_account_name(ferret_service))
    |> B.namespace(namespace(ferret_service, state))
    |> B.add_owner(ferret_service)
  end

  def service(ferret_service, _battery, %StateSummary{} = state) do
    spec =
      %{}
      |> Map.put("selector", %{"battery/component" => @app_name, "battery/owner" => ferret_service.id})
      |> Map.put("ports", [
        %{"name" => "rpc", "port" => 27_017, "protocol" => "TCP"},
        %{"name" => "debug", "port" => 8088, "protocol" => "TCP"}
      ])

    :service
    |> B.build_resource()
    |> B.app_labels(@app_name)
    |> B.name(service_name(ferret_service))
    |> B.namespace(namespace(ferret_service, state))
    |> B.spec(spec)
    |> B.add_owner(ferret_service)
  end

  defp deployment(%FerretService{} = ferret_service, battery, %StateSummary{} = state) do
    template =
      %{
        "metadata" => %{
          "labels" => %{"battery/managed" => "true"}
        },
        "spec" => %{
          "containers" => [container(ferret_service, battery, state)],
          "serviceAccountName" => service_account_name(ferret_service)
        }
      }
      |> B.app_labels(service_name(ferret_service))
      |> B.component_labels(@app_name)
      |> B.add_owner(ferret_service)

    spec =
      %{}
      |> Map.put("selector", %{
        "matchLabels" => %{"battery/app" => service_name(ferret_service), "battery/component" => @app_name}
      })
      |> Map.put("replicas", ferret_service.instances)
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.app_labels(@app_name)
    |> B.name(service_name(ferret_service))
    |> B.namespace(namespace(ferret_service, state))
    |> B.spec(spec)
    |> B.add_owner(ferret_service)
  end

  @spec get_cluster(FerretService.t(), StateSummary.t()) :: CommonCore.Postgres.Cluster.t() | nil
  defp get_cluster(%FerretService{} = ferret_service, %StateSummary{} = state) do
    Enum.find(state.postgres_clusters, fn cluster -> cluster.id == ferret_service.postgres_cluster_id end)
  end

  defp container(%FerretService{} = ferret_service, battery, %StateSummary{} = state) do
    pg = get_cluster(ferret_service, state)
    user = List.first(pg.users)

    %{}
    |> Map.put("name", "ferret")
    |> Map.put("image", battery.config.ferretdb_image)
    |> Map.put("resources", resources(ferret_service))
    |> Map.put("ports", [
      %{"containerPort" => 27_017, "name" => "rpc"},
      %{"containerPort" => 8088, "name" => "debug"}
    ])
    |> Map.put("env", [
      %{
        "name" => "FERRETDB_POSTGRESQL_URL",
        "valueFrom" => B.secret_key_ref("cloudnative-pg.pg-#{pg.name}.#{user.username}", "dsn")
      },
      %{"name" => "FERRETDB_TELEMETRY", "value" => "disable"},
      %{"name" => "DO_NOT_TRACK", "value" => "true"}
    ])
  end

  defp resources(%FerretService{} = ferret_service) do
    limits =
      %{}
      |> maybe_put("cpu", format_cpu_resource(ferret_service.cpu_limits))
      |> maybe_put("memory", format_resource(ferret_service.memory_limits))

    requests =
      %{}
      |> maybe_put("cpu", format_cpu_resource(ferret_service.cpu_requested))
      |> maybe_put("memory", format_resource(ferret_service.memory_requested))

    %{} |> maybe_put("limits", limits) |> maybe_put("requests", requests)
  end

  defp format_resource(nil), do: nil
  defp format_resource(value), do: to_string(value)

  defp format_cpu_resource(nil), do: nil

  defp format_cpu_resource(value) do
    "#{value}m"
  end

  def service_name(%FerretService{} = ferret_service) do
    "ferret-#{ferret_service.name}"
  end

  defp service_account_name(%FerretService{} = ferret_service) do
    "ferret-#{ferret_service.name}"
  end

  defp namespace(%FerretService{} = ferret_service, %StateSummary{} = state) do
    pg_cluster = get_cluster(ferret_service, state)
    StateSummary.PostgresState.cluster_namespace(state, pg_cluster)
  end
end
