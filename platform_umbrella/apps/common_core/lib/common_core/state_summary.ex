defmodule CommonCore.StateSummary do
  @moduledoc """
    The StateSummary module provides a struct to store and manage system state information.

    ## Example Usage

    ```elixir
    # Create a new state summary struct
    state_summary = %CommonCore.StateSummary{}

    # Access fields
    batteries = state_summary.batteries
    postgres_clusters = state_summary.postgres_clusters

    # Update fields
    state_summary = %{state_summary | batteries: [%CommonCore.Batteries.SystemBattery{}]}

  """
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
