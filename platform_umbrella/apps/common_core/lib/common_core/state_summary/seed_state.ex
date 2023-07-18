defmodule CommonCore.StateSummary.SeedState do
  alias CommonCore.Batteries.BatteryCoreConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.StateSummary
  alias CommonCore.Batteries.Catalog
  alias CommonCore.Defaults

  def seed(:everything) do
    %StateSummary{
      batteries: batteries(),
      postgres_clusters:
        pg_clusters([
          Defaults.ControlDB.control_cluster(),
          Defaults.GiteaDB.gitea_cluster(),
          Defaults.HarborDB.harbor_pg_cluster()
        ]),
      redis_clusters: redis_clusters([Defaults.HarborDB.harbor_redis_cluster()])
    }
  end

  def seed(:dev) do
    summary = %StateSummary{
      batteries:
        batteries([
          :battery_core,
          :postgres,
          :istio,
          :istio_gateway,
          :timeline,
          :metallb
        ]),
      postgres_clusters: pg_clusters([Defaults.ControlDB.control_cluster()])
    }

    add_dev_infra_user(summary)
  end

  def seed(:slim_dev) do
    summary = %StateSummary{
      batteries:
        batteries([
          :battery_core,
          :postgres,
          :istio,
          :istio_gateway
        ]),
      postgres_clusters: pg_clusters([Defaults.ControlDB.control_cluster()])
    }

    # The things below are here on the client side.
    # They require that we know something about the
    # what the client side looks like.
    #
    add_dev_infra_user(summary)
  end

  defp add_dev_infra_user(%StateSummary{} = summary) do
    %StateSummary{summary | batteries: Enum.map(summary.batteries, &add_dev_infra_to_battery/1)}
  end

  defp add_dev_infra_to_battery(%{type: :postgres} = battery) do
    update_in(battery, [Access.key(:config, %{}), Access.key(:infra_users, [])], fn users ->
      clean_users = users || []

      [
        %CommonCore.Postgres.PGInfraUser{
          username: "batterydbuser",
          generated_key: "not-real",
          roles: ["createdb", "superuser", "login"]
        }
        | clean_users
      ]
    end)
  end

  defp add_dev_infra_to_battery(battery), do: battery

  defp redis_clusters(args_list) do
    Enum.map(args_list, &CommonCore.Redis.FailoverCluster.to_fresh_cluster/1)
  end

  defp pg_clusters(args_list) do
    Enum.map(args_list, &CommonCore.Postgres.Cluster.to_fresh_cluster/1)
  end

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
