defmodule KubeServices.SnapshotApply.Steps do
  alias ControlServer.SnapshotApply.EctoSteps
  alias ControlServer.SnapshotApply.StateSnapshot
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath
  alias KubeServices.SnapshotApply.ResourcePathWorker

  alias KubeExt.Hashing
  alias KubeExt.KubeState
  alias KubeResources.ConfigGenerator

  require Logger

  def creation! do
    {:ok, snap} = EctoSteps.create_snap()
    snap
  end

  @spec generation!(KubeSnapshot.t()) :: [Ecto.UUID.t()]
  def generation!(%KubeSnapshot{} = snap) do
    {:ok, paths} =
      EctoSteps.snap_generation(
        snap,
        StateSnapshot.materialize!(),
        &ConfigGenerator.materialize/1
      )

    paths
  end

  @spec get_rp(binary()) :: ResourcePath.t()
  def get_rp(id) do
    EctoSteps.get_rp(id)
  end

  @spec launch_resource_path_jobs([]) :: [Oban.Job.t()]
  def launch_resource_path_jobs(resource_path_ids) do
    resource_path_ids
    |> Enum.map(fn id -> ResourcePathWorker.new(%{id: id}) end)
    |> Oban.insert_all(timeout: 60_000)
  end

  @spec apply_resource_path(ResourcePath.t()) ::
          {:error, any} | {:ok, :applied | :state_hash_match}
  def apply_resource_path(%ResourcePath{} = rp) do
    if kube_state_different?(rp) do
      do_apply(rp)
    else
      {:ok, :state_hash_match}
    end
  end

  def update_resource_path(%ResourcePath{} = rp, {result, reason}) do
    is_success = resource_path_result_is_success?(result)
    EctoSteps.update_rp(rp, is_success, reason(reason))
  end

  @spec update_applying!(KubeSnapshot.t()) :: KubeSnapshot.t()
  def update_applying!(%KubeSnapshot{} = snap) do
    with {:ok, new_snap} <- EctoSteps.update_snap_status(snap, :applying) do
      new_snap
    end
  end

  @spec summarize!(KubeSnapshot.t()) :: KubeSnapshot.t()
  def summarize!(%KubeSnapshot{} = snap) do
    status = snap_status(get_result_count(snap))

    with {:ok, new_snap} <- EctoSteps.update_snap_status(snap, status) do
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

  defp kube_state_different?(%ResourcePath{} = rp) do
    case KubeState.get(rp.type, rp.namespace, rp.name) do
      # Resource path doesn't have the whole annotated
      # resource so just check the equality of the hashes here.
      {:ok, current_resource} ->
        current_resource
        |> Hashing.get_hash()
        |> Hashing.different?(rp.hash)

      _ ->
        true
    end
  end

  defp do_apply(%ResourcePath{} = rp) do
    case KubeExt.apply_single(KubeExt.ConnectionPool.get(), rp.content_addressable_resource.value) do
      {:ok, _result} -> {:ok, :applied}
      {:error, %{error: error_reason}} -> {:error, error_reason}
      {:error, reason} -> {:error, reason}
    end
  end
end
