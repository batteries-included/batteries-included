defmodule CommonCore.SystemState.SeedState do
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.SystemState.StateSummary
  alias CommonCore.Batteries.Catalog
  alias CommonCore.Defaults
  alias CommonCore.DockerIps

  def seed(:everything) do
    state_summary = %StateSummary{
      batteries: batteries(),
      postgres_clusters:
        pg_clusters([
          Defaults.ControlDB.control_cluster(),
          Defaults.GiteaDB.gitea_cluster(),
          Defaults.HarborDB.harbor_pg_cluster()
        ]),
      redis_clusters: redis_clusters([Defaults.HarborDB.harbor_redis_cluster()])
    }

    add_docker_lb_ips(state_summary)
  end

  def seed(:local_kind) do
    summary = %StateSummary{
      batteries:
        batteries([
          :battery_core,
          :postgres_operator,
          :postgres,
          :istio,
          :metallb,
          :metallb_ip_pool,
          :control_server
        ]),
      postgres_clusters: pg_clusters([Defaults.ControlDB.control_cluster()])
    }

    add_docker_lb_ips(summary)
  end

  def seed(:dev) do
    summary = %StateSummary{
      batteries:
        batteries([
          :battery_core,
          :postgres_operator,
          :postgres,
          :istio,
          :metallb,
          :metallb_ip_pool
        ]),
      postgres_clusters: pg_clusters([Defaults.ControlDB.control_cluster()])
    }

    # The things below are here on the client side.
    # They require that we know something about the
    # what the client side looks like.
    #
    summary
    |> add_docker_lb_ips()
    |> add_dev_infra_user()
  end

  def seed(:limited) do
    %StateSummary{
      batteries:
        batteries([
          :battery_core,
          :postgres_operator,
          :postgres
        ]),
      postgres_clusters: pg_clusters([Defaults.ControlDB.control_cluster()])
    }
  end

  defp add_docker_lb_ips(%StateSummary{} = state_summary) do
    %StateSummary{
      state_summary
      | ip_address_pools: get_lb_ranges() ++ state_summary.ip_address_pools
    }
  end

  defp add_dev_infra_user(%StateSummary{} = summary) do
    %StateSummary{summary | batteries: Enum.map(summary.batteries, &add_dev_infra_to_battery/1)}
  end

  defp add_dev_infra_to_battery(%{type: :postgres_operator} = battery) do
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

  def get_lb_ranges do
    # I'm not 100% sure that if we add more
    # LB's they won't hit the gateway and the node that
    # are in the start of the range.
    #
    # So split the range and drop the start.

    case get_docker_cidr() do
      nil ->
        []

      cidr ->
        cidr
        |> CIDR.split(cidr.mask + 1)
        |> Enum.to_list()
        |> Enum.drop(1)
        |> Enum.map(fn c -> to_string(c) end)
        |> Enum.with_index()
        |> Enum.map(fn {el, idx} ->
          # This is kind of silly but *shrug*
          #
          # We are creating the StateSummary struct that
          # has a type signature. So regardless of the fact that
          # this map that we turn into struct is almost directly going
          # to be turned back into a map, we do this.
          CommonCore.MetalLB.IPAddressPool.to_fresh_ip_address_pool(%{
            name: "kind-#{idx}",
            subnet: el
          })
        end)
    end
  end

  defp get_docker_cidr do
    DockerIps.get_kind_ips()
    |> Enum.map(&CIDR.parse/1)
    |> List.first()
  end

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
    |> Enum.uniq_by(& &1.type)
    |> Enum.map(&CatalogBattery.to_fresh_system_battery/1)
  end
end
