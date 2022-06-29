defmodule KubeServices.SnapshotApply.Steps do
  import K8s.Resource.FieldAccessors

  alias ControlServer.Repo
  alias ControlServer.Services
  alias ControlServer.SnapshotApply, as: ControlSnapshotApply
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath
  alias Ecto.Multi

  alias KubeExt.Hashing
  alias KubeExt.KubeState
  alias KubeResources.ConfigGenerator

  require Logger

  def creation! do
    with {:ok, snapshot} <- ControlSnapshotApply.create_kube_snapshot() do
      snapshot
    end
  end

  @spec generation!(KubeSnapshot.t()) :: [ResourcePath.t()]
  def generation!(%KubeSnapshot{} = kube_snapshot) do
    with {:ok, resource_map} <- run_resource_paths_transaction(kube_snapshot) do
      resource_map
      |> Map.values()
      |> List.flatten()
      |> Enum.filter(fn
        %ResourcePath{} -> true
        _ -> false
      end)
    end
  end

  @spec launch_resource_path_jobs([ResourcePath.t()]) :: [Oban.Job.t()]
  def launch_resource_path_jobs(resource_paths) do
    resource_paths
    |> Enum.map(fn rp -> KubeServices.SnapshotApply.ResourcePathWorker.new(%{id: rp.id}) end)
    |> Oban.insert_all()
  end

  @spec apply_resource_path(ResourcePath.t()) ::
          {:error, any} | {:ok, :applied | :state_hash_match}
  def apply_resource_path(%ResourcePath{} = rp) do
    if does_hash_match(rp) do
      {:ok, :state_hash_match}
    else
      do_apply(rp)
    end
  end

  def update_resource_path(%ResourcePath{} = rp, {result, reason}) do
    is_success = resource_path_result_is_success?(result)

    ControlSnapshotApply.update_resource_path(rp, %{
      is_success: is_success,
      apply_result: reason |> reason() |> String.slice(0, 200)
    })
  end

  @spec update_applying!(KubeSnapshot.t()) :: KubeSnapshot.t()
  def update_applying!(%KubeSnapshot{} = snap) do
    with {:ok, new_snap} <- ControlSnapshotApply.update_kube_snapshot(snap, %{status: :applying}) do
      new_snap
    end
  end

  @spec summarize!(KubeSnapshot.t()) :: KubeSnapshot.t()
  def summarize!(%KubeSnapshot{} = snap) do
    with {:ok, new_snap} <-
           ControlSnapshotApply.update_kube_snapshot(snap, %{
             status: snap_status(get_result_count(snap))
           }) do
      new_snap
    end
  end

  defp snap_status(%{nil: nil_count} = _counts) when nil_count > 0 do
    :applying
  end

  defp snap_status(%{false: error_count} = _counts) when error_count > 0 do
    :error
  end

  defp snap_status(%{true: ok_count} = _counts) when ok_count > 0 do
    :ok
  end

  defp get_result_count(snap) do
    snap.resource_paths
    |> Enum.group_by(fn rp -> rp.is_success end)
    |> Enum.map(fn {key, list} -> {key, length(list)} end)
    |> Enum.into(%{})
  end

  defp resource_path_result_is_success?(:ok), do: true
  defp resource_path_result_is_success?(_result), do: false

  defp reason(reason_atom) when is_atom(reason_atom), do: Atom.to_string(reason_atom)
  defp reason(reason_string) when is_binary(reason_string), do: reason_string
  defp reason(obj), do: inspect(obj)

  defp does_hash_match(%ResourcePath{} = rp) do
    current_hash =
      rp.resource_value
      |> KubeState.get_resource()
      |> Hashing.get_hash()

    current_hash == rp.hash
  end

  defp do_apply(%ResourcePath{} = rp) do
    case KubeExt.apply_single(KubeExt.ConnectionPool.get(), rp.resource_value) do
      {:ok, _result} -> {:ok, :applied}
      {:error, %{error: error_reason}} -> {:error, error_reason}
      {:error, reason} -> {:error, reason}
    end
  end

  defp run_resource_paths_transaction(%KubeSnapshot{} = kube_snapshot) do
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

  defp resource_paths_multi(base_services, kube_snapshot) do
    {_count, multi} =
      base_services
      |> Enum.map(&ConfigGenerator.materialize/1)
      |> Enum.reduce(%{}, &Map.merge/2)
      |> Enum.map(fn {path, resource} ->
        filled_resource = Hashing.decorate_content_hash(resource)

        ResourcePath.changeset(%ResourcePath{}, %{
          path: path,
          hash: Hashing.get_hash(filled_resource),
          name: name(filled_resource),
          namespace: namespace(filled_resource),
          api_version: api_version(filled_resource),
          kind: kind(filled_resource),
          resource_value: filled_resource,
          kube_snapshot_id: kube_snapshot.id
        })
      end)
      |> Enum.reduce({0, Multi.new()}, fn changeset, {n, multi} ->
        {n + 1, Multi.insert(multi, "resource_path_#{n}", changeset)}
      end)

    multi
  end
end
