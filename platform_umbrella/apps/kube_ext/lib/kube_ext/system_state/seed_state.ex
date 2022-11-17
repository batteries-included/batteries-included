defmodule KubeExt.SystemState.SeedState do
  alias KubeExt.SystemState.StateSummary
  alias KubeExt.Defaults

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
    %StateSummary{
      batteries:
        Enum.map(
          [:battery_core, :postgres_operator, :database_internal, :istio, :istio_istiod],
          &Defaults.Catalog.get/1
        ),
      postgres_clusters: [Defaults.ControlDB.control_cluster()]
    }
  end
end
