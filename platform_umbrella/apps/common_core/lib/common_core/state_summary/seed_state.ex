defmodule CommonCore.StateSummary.SeedState do
  @moduledoc false
  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Defaults
  alias CommonCore.StateSummary

  def seed(:everything) do
    %StateSummary{
      batteries: batteries(),
      postgres_clusters:
        pg_clusters([
          Defaults.ControlDB.control_cluster(),
          Defaults.KeycloakDB.pg_cluster(),
          Defaults.GiteaDB.gitea_cluster()
        ]),
      keycloak_state: keycloak_state()
    }
  end

  def seed(:dev) do
    %StateSummary{
      batteries:
        batteries([
          :battery_core,
          :cloudnative_pg,
          :istio,
          :istio_gateway,
          :stale_resource_cleaner,
          :metallb
        ]),
      postgres_clusters: pg_clusters([Defaults.ControlDB.control_cluster()])
    }
  end

  def seed(:slim_dev) do
    %StateSummary{
      batteries:
        batteries([
          :battery_core,
          :cloudnative_pg,
          :istio,
          :istio_gateway,
          :stale_resource_cleaner
        ]),
      postgres_clusters: pg_clusters([Defaults.ControlDB.control_cluster()])
    }
  end

  defp pg_clusters(clusters) do
    Enum.map(clusters, fn cluster -> cluster |> add_local_user() |> CommonCore.Postgres.Cluster.to_fresh_cluster() end)
  end

  defp keycloak_state do
    %CommonCore.StateSummary.KeycloakSummary{}
  end

  defp add_local_user(%{name: cluster_name, users: users} = cluster) do
    if cluster_name == Defaults.ControlDB.cluster_name() do
      users = users || []
      %{cluster | users: [Defaults.ControlDB.local_user() | users]}
    else
      cluster
    end
  end

  defp add_local_user(%{} = cluster), do: cluster

  defp batteries do
    Enum.map(Catalog.all(), &CatalogBattery.to_fresh_system_battery/1)
  end

  defp batteries(types) do
    types
    |> Enum.map(&Catalog.get/1)
    |> Enum.flat_map(&Catalog.get_recursive/1)
    |> Enum.map(&CatalogBattery.to_fresh_system_battery/1)
    |> Enum.uniq_by(& &1.type)
    |> Enum.map(&clean_config/1)
  end

  defp clean_config(%SystemBattery{type: :battery_core, config: config} = sb) do
    %SystemBattery{sb | config: %BatteryCoreConfig{config | secret_key: nil}}
  end

  defp clean_config(x), do: x
end
