defmodule CommonCore.SystemState.StateSummary do
  @derive Jason.Encoder
  defstruct batteries: [],
            postgres_clusters: [],
            redis_clusters: [],
            notebooks: [],
            knative_services: [],
            ceph_clusters: [],
            ceph_filesystems: [],
            ip_address_pools: [],
            kube_state: %{}

  @type t :: %__MODULE__{
          batteries: list(CommonCore.Batteries.SystemBattery.t()),
          postgres_clusters: list(CommonCore.Postgres.Cluster.t()),
          redis_clusters: list(CommonCore.Redis.FailoverCluster.t()),
          notebooks: list(CommonCore.Notebooks.JupyterLabNotebook.t()),
          knative_services: list(CommonCore.Knative.Service.t()),
          ceph_clusters: list(CommonCore.Rook.CephCluster.t()),
          ceph_filesystems: list(CommonCore.Rook.CephFilesystem.t()),
          ip_address_pools: list(CommonCore.MetalLB.IPAddressPool.t()),
          kube_state: map()
        }
end
