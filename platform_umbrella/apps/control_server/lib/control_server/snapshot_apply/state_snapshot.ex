defmodule ControlServer.SnapshotApply.StateSnapshot do
  alias ControlServer.Batteries
  alias ControlServer.Knative
  alias ControlServer.Notebooks
  alias ControlServer.Postgres
  alias ControlServer.Redis
  alias ControlServer.Rook

  alias KubeExt.SnapshotApply.StateSnapshot

  alias Ecto.Multi

  @type t :: %StateSnapshot{
          system_batteries: list(Batteries.SystemBattery.t()),
          postgres_clusters: list(Postgres.Cluster.t()),
          redis_clusters: list(Redis.FailoverCluster.t()),
          notebooks: list(Notebooks.JupyterLabNotebook.t()),
          ceph_clusters: list(Rook.CephCluster.t()),
          ceph_filesystems: list(Rook.CephFilesystem.t()),
          kube_state: map()
        }

  @spec materialize! :: t()
  def materialize! do
    with {:ok, res} <- transaction() do
      struct(StateSnapshot, res)
    end
  end

  def transaction do
    Multi.new()
    |> Multi.all(:system_batteries, Batteries.SystemBattery)
    |> Multi.all(:postgres_clusters, Postgres.Cluster)
    |> Multi.all(:redis_clusters, Redis.FailoverCluster)
    |> Multi.all(:notebooks, Notebooks.JupyterLabNotebook)
    |> Multi.all(:knative_services, Knative.Service)
    |> Multi.all(:ceph_clusters, Rook.CephCluster)
    |> Multi.all(:ceph_filesystems, Rook.CephFilesystem)
    |> Multi.run(:kube_state, fn _repo, _state ->
      {:ok, KubeExt.KubeState.snapshot()}
    end)
    |> ControlServer.Repo.transaction()
  end
end
