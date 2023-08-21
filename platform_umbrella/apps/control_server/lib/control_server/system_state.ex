defmodule ControlServer.SystemState do
  @moduledoc false
  alias Ecto.Multi

  def transaction do
    Multi.new()
    |> Multi.all(:batteries, CommonCore.Batteries.SystemBattery)
    |> Multi.all(:postgres_clusters, CommonCore.Postgres.Cluster)
    |> Multi.all(:redis_clusters, CommonCore.Redis.FailoverCluster)
    |> Multi.all(:notebooks, CommonCore.Notebooks.JupyterLabNotebook)
    |> Multi.all(:knative_services, CommonCore.Knative.Service)
    |> Multi.all(:ceph_clusters, CommonCore.Rook.CephCluster)
    |> Multi.all(:ceph_filesystems, CommonCore.Rook.CephFilesystem)
    |> Multi.all(:ip_address_pools, CommonCore.MetalLB.IPAddressPool)
    |> ControlServer.Repo.transaction()
  end
end
