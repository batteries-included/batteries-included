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
  use TypedStruct

  alias CommonCore.StateSummary.KeycloakSummary

  @derive Jason.Encoder

  typedstruct do
    field :batteries, list(CommonCore.Batteries.SystemBattery.t()), default: []
    field :postgres_clusters, list(CommonCore.Postgres.Cluster.t()), default: []
    field :redis_clusters, list(CommonCore.Redis.FailoverCluster.t()), default: []
    field :notebooks, list(CommonCore.Notebooks.JupyterLabNotebook.t()), default: []
    field :knative_services, list(CommonCore.Knative.Service.t()), default: []
    field :ceph_clusters, list(CommonCore.Rook.CephCluster.t()), default: []
    field :ceph_filesystems, list(CommonCore.Rook.CephFilesystem.t()), default: []
    field :ip_address_pools, list(CommonCore.MetalLB.IPAddressPool.t()), default: []
    field :kube_state, map(), default: %{}
    field :keycloak_state, KeycloakSummary.t(), enforce: false
  end
end
