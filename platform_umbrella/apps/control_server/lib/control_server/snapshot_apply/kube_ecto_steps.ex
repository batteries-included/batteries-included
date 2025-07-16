defmodule ControlServer.SnapshotApply.KubeEctoSteps do
  @moduledoc false

  use ControlServer, :context

  import ControlServer.SnapshotApply.Kube
  import K8s.Resource.FieldAccessors

  alias CommonCore.ApiVersionKind
  alias CommonCore.Resources.Hashing
  alias ControlServer.ContentAddressable.Document
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath

  @max_reason_length 255
  @generation_timeout 60_000

  def create_snap(attrs \\ %{}) do
    create_kube_snapshot(attrs)
  end

  def snap_generation(%KubeSnapshot{} = snap, resource_map) do
    Multi.new()
    |> Multi.run(:addressables, fn _repo, _ ->
      {:ok, document_args(resource_map)}
    end)
    |> Multi.all(
      :existing_hashes,
      fn %{addressables: addressables} ->
        # We're assuming there will be lots of hashes that already have content
        # So rather than pass all that content along the wire, just check for what's there.
        get_already_inserted_hashes(addressables)
      end
    )
    |> Multi.insert_all(
      :new_content,
      Document,
      fn %{addressables: addressables} = ctx ->
        # The documents query will have
        # returned hashes. These don't need to be persisted.
        found_hashes = get_hashes_set(ctx)
        Enum.reject(addressables, fn adr -> MapSet.member?(found_hashes, adr.hash) end)
      end,
      returning: [:id, :hash]
    )
    |> Multi.insert_all(
      :resource_paths,
      ResourcePath,
      fn _ ->
        now = DateTime.utc_now()

        # Now we can create the ResourcePath that can be synced to kubernetes.
        # Since Documents have known ID's and
        # we have the hash of the content it's safe to create
        # refencing `document_id`.
        Enum.map(resource_map, fn {path, resource} ->
          rp_args_from_resource(snap, resource, path, now)
        end)
      end,
      returning: true
    )
    # Finally run the transaction.
    |> Repo.transaction(timeout: @generation_timeout)
  end

  @spec update_snap_status(KubeSnapshot.t(), any) ::
          {:ok, KubeSnapshot.t()} | {:error, Ecto.Changeset.t()}
  def update_snap_status(%KubeSnapshot{} = snap, status) do
    update_kube_snapshot(snap, %{status: status})
  end

  @spec update_rp(ResourcePath.t(), boolean(), binary()) ::
          {:ok, ResourcePath.t()} | {:error, Ecto.Changeset.t()}
  def update_rp(%ResourcePath{} = rp, is_success, reason) do
    update_resource_path(rp, %{
      is_success: is_success,
      apply_result: String.slice(reason, 0, @max_reason_length)
    })
  end

  @spec update_all_rp(list(), boolean(), binary()) :: any
  def update_all_rp(paths, is_success, reason) do
    ids = Enum.map(paths, & &1.id)

    final_reason = String.slice(reason, 0, @max_reason_length)

    ControlServer.Repo.update_all(from(rp in ResourcePath, where: rp.id in ^ids),
      set: [is_success: is_success, apply_result: final_reason]
    )
  end

  defp get_already_inserted_hashes(addressables) do
    hashes = Enum.map(addressables, & &1.hash)

    from(car in Document,
      where: car.hash in ^hashes,
      select: [car.hash]
    )
  end

  defp get_hashes_set(ctx), do: ctx |> Map.get(:existing_hashes, []) |> List.flatten() |> MapSet.new()

  defp document_args(resource_map) do
    # Grab now so that all addressables are created at the same time.
    now = DateTime.utc_now()

    resource_map
    |> Map.values()
    |> Enum.map(fn r -> document_args_from_resource(r, now) end)
    # group by id and dedupe
    |> Enum.group_by(& &1.id)
    |> Enum.map(fn {_key, [first | _rest]} -> first end)
  end

  defp rp_args_from_resource(%KubeSnapshot{} = snap, %{} = resource, path, now) do
    hash = Hashing.get_hash(resource)

    %{
      id: CommonCore.Ecto.BatteryUUID.autogenerate(),
      path: path,
      hash: hash,
      document_id: Document.hash_to_uuid!(hash),
      name: name(resource),
      namespace: namespace(resource),
      type: ApiVersionKind.resource_type!(resource),
      kube_snapshot_id: snap.id,
      inserted_at: now,
      updated_at: now
    }
  end

  defp document_args_from_resource(resource, now) do
    hash = Hashing.get_hash(resource)
    id = Document.hash_to_uuid!(hash)

    %{
      value: resource,
      hash: hash,
      id: id,
      inserted_at: now,
      updated_at: now
    }
  end
end
