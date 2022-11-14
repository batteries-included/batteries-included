defmodule KubeExt.SystemState.SeedState do
  alias KubeExt.SystemState.StateSummary
  alias KubeExt.RequiredDatabases
  alias KubeExt.Defaults

  def seed, do: seed(KubeExt.cluster_type())

  def seed(:everything) do
    %StateSummary{
      batteries: Defaults.Catalog.all(),
      postgres_clusters: [
        RequiredDatabases.Control.control_cluster(),
        RequiredDatabases.Gitea.gitea_cluster(),
        RequiredDatabases.Harbor.harbor_pg_cluster(),
        RequiredDatabases.OryHydra.hydra_cluster()
      ],
      redis_clusters: [RequiredDatabases.Harbor.harbor_redis_cluster()]
    }
  end

  def seed(_type) do
    %StateSummary{
      batteries:
        Enum.map(
          [:battery_core, :postgres_operator, :database_internal, :istio, :istio_istiod],
          &Defaults.Catalog.get/1
        ),
      postgres_clusters: [RequiredDatabases.Control.control_cluster()]
    }
  end
end
