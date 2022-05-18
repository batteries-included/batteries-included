defmodule KubeServices.SnapshotApply.Steps do
  alias ControlServer.Repo
  alias ControlServer.Services
  alias ControlServer.SnapshotApply, as: ControlSnapshotApply
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath

  alias Ecto.Multi

  alias KubeExt.Hashing

  alias KubeResources.ConfigGenerator

  alias KubeServices.SnapshotApply.SnapshotSupervisor

  require Logger

  def creation(%KubeSnapshot{} = kube_snapshot) do
    # Remove all resource path data.
    kube_snapshot
    |> ControlSnapshotApply.resource_paths_for_snapshot()
    |> ControlServer.Repo.delete_all()
  end

  def generation(%KubeSnapshot{} = kube_snapshot) do
    Multi.new()
    |> Multi.run(:base_services, fn repo, _ ->
      # Get the list of base services inside of the transaction
      {:ok, Services.all_including_config(repo)}
    end)
    |> Multi.merge(fn %{base_services: base_services} ->
      # Then create a huge multi with each insert.
      resource_paths_multi(base_services, kube_snapshot)
    end)
    # Finally run the transaction.
    |> Repo.transaction()
  end

  def application(%KubeSnapshot{} = kube_snapshot, worker_pid) do
    kube_snapshot
    |> ControlSnapshotApply.resource_paths_for_snapshot()
    |> Repo.all()
    |> Enum.map(fn rp -> apply_resource_path(rp, worker_pid) end)
  end

  def apply do
    Logger.debug("Waiting on applying to complete.")
  end

  defp resource_paths_multi(base_services, kube_snapshot) do
    {_count, multi} =
      base_services
      |> Enum.map(&ConfigGenerator.materialize/1)
      |> Enum.reduce(&Map.merge/2)
      |> Enum.map(fn {path, resource} ->
        ResourcePath.changeset(%ResourcePath{}, %{
          path: path,
          hash: Hashing.get_hash(resource),
          resource_value: resource,
          kube_snapshot_id: kube_snapshot.id
        })
      end)
      |> Enum.reduce({0, Multi.new()}, fn changeset, {n, multi} ->
        {n + 1, Multi.insert(multi, "resource_path_#{n}", changeset)}
      end)

    multi
  end

  defp apply_resource_path(%ResourcePath{} = rp, worker_pid) do
    SnapshotSupervisor.start_resource_path(rp, worker_pid)
  end
end
