defmodule KubeExt.SystemState.SeedState do
  alias KubeExt.SystemState.StateSummary
  alias KubeExt.Defaults
  alias KubeExt.DockerIps

  def seed, do: seed(KubeExt.cluster_type())

  def seed(:everything) do
    %StateSummary{
      batteries: Defaults.Catalog.all(),
      postgres_clusters: [
        Defaults.ControlDB.control_cluster(),
        Defaults.GiteaDB.gitea_cluster(),
        Defaults.HarborDB.harbor_pg_cluster()
      ],
      redis_clusters: [Defaults.HarborDB.harbor_redis_cluster()]
    }
  end

  def seed(_type) do
    state_summary = %StateSummary{
      batteries:
        Enum.map(
          [
            :battery_core,
            :postgres_operator,
            :database_internal,
            :istio,
            :istio_istiod,
            :metallb,
            :metallb_ip_pool
          ],
          &Defaults.Catalog.get/1
        ),
      postgres_clusters: [Defaults.ControlDB.control_cluster()]
    }

    add_docker_lb_ips(state_summary)
  end

  defp add_docker_lb_ips(%StateSummary{} = state_summary) do
    %StateSummary{
      state_summary
      | ip_address_pools: get_lb_ranges() ++ state_summary.ip_address_pools
    }
  end

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
        |> Enum.map(fn {el, idx} -> %{name: "kind-#{idx}", subnet: el} end)
    end
  end

  defp get_docker_cidr do
    DockerIps.get_kind_ips()
    |> Enum.map(&CIDR.parse/1)
    |> List.first()
  end
end
