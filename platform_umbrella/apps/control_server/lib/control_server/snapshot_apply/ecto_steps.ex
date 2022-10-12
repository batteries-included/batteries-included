defmodule ControlServer.SnapshotApply.EctoSteps do
  import Ecto.Query
  import K8s.Resource.FieldAccessors

  alias ControlServer.Repo
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath
  alias ControlServer.SnapshotApply.ContentAddressableResource
  alias ControlServer.Batteries.SystemBattery

  alias KubeExt.Hashing
  alias KubeExt.ApiVersionKind

  alias Ecto.Multi

  @max_reason_length 255
  @generation_timeout 60_000

  def create_snap do
    ControlServer.SnapshotApply.create_kube_snapshot()
  end

  def snap_generation_transaction(%KubeSnapshot{} = snap, resource_gen_func) do
    Multi.new()
    |> Multi.all(:batteries, SystemBattery)
    |> Multi.merge(fn %{batteries: batteries} ->
      generation_multi(snap, batteries, resource_gen_func)
    end)
    # Finally run the transaction.
    |> Repo.transaction(timeout: @generation_timeout)
    # ContentAddressableResource info isn't needed. So
    # keep the resource path ids only
    |> then(fn {:ok, result} ->
      {_count, paths} = Map.get(result, :resource_paths, {0, []})
      {:ok, Enum.map(paths, & &1.id)}
    end)
  end

  def update_snap_status(%KubeSnapshot{} = snap, status) do
    ControlServer.SnapshotApply.update_kube_snapshot(snap, %{status: status})
  end

  def update_rp(%ResourcePath{} = rp, is_success, reason) do
    ControlServer.SnapshotApply.update_resource_path(rp, %{
      is_success: is_success,
      apply_result: String.slice(reason, 0, @max_reason_length)
    })
  end

  def get_rp(id) do
    ResourcePath
    |> Repo.get(id)
    |> Repo.preload(:content_addressable_resource)
  end

  # This is the main method of a very complex multi.
  #
  # We're going to return a multi here that will be merged
  # into the above. This method takes in the snapshot that
  # this is for, a list of system batteries, and a function
  # for generating a map of resources.
  #
  # We take the list of batteries here so that the snapshot
  # is an atomic snapshot across the whole table.
  defp generation_multi(snap, batteries, resource_gen_func) do
    resource_map = resource_map(batteries, resource_gen_func)
    addressables = addressables(resource_map)

    Multi.new()
    |> Multi.all(
      :content_addressable_resources,
      fn _ ->
        # We're assuming there will be lots of hashes that already have content
        # So rather than pass all that content along the wire, just check for what's there.
        get_already_inserted_hashes(addressables)
      end
    )
    |> Multi.insert_all(
      :new_content,
      ContentAddressableResource,
      fn ctx ->
        # The content_addressable_resources query will have
        # returned hashes. These don't need to be persisted.
        found_hashes = get_hashes_set(ctx)
        Enum.reject(addressables, fn adr -> MapSet.member?(found_hashes, adr.hash) end)
      end,
      returning: [:id, :hash]
    )
    |> Multi.insert_all(
      :resource_paths,
      ResourcePath,
      fn _ctx ->
        now = DateTime.utc_now()

        # Now we can create the ResourcePath that can be synced to kubernetes.
        # Since ContentAddressableResources have known ID's and
        # we have the hash of the content it's safe to create
        # refencing `content_addressable_resource_id`.
        Enum.map(resource_map, fn {path, resource} ->
          raw_rp_from_resource(snap, resource, path, now)
        end)
      end,
      returning: [:id]
    )
  end

  def get_already_inserted_hashes(addressables) do
    hashes = Enum.map(addressables, & &1.hash)

    from(car in ContentAddressableResource,
      where: car.hash in ^hashes,
      select: [car.hash]
    )
  end

  def get_hashes_set(ctx),
    do: ctx |> Map.get(:content_addressable_resources, []) |> List.flatten() |> MapSet.new()

  defp resource_map(batteries, resource_gen_func) do
    resource_gen_func.(batteries)
  end

  defp addressables(resource_map) do
    # Grab now so that all addressables are created at the same time.
    now = DateTime.utc_now()

    resource_map
    |> Map.values()
    |> Enum.map(fn r -> raw_addressable_from_resource(r, now) end)
    # group by id and dedupe
    |> Enum.group_by(& &1.id)
    |> Enum.map(fn {_key, [first | _rest]} -> first end)
  end

  defp raw_rp_from_resource(%KubeSnapshot{} = snap, %{} = resource, path, now) do
    hash = Hashing.get_hash(resource)

    %{
      path: path,
      hash: hash,
      content_addressable_resource_id: ContentAddressableResource.hash_to_uuid!(hash),
      name: name(resource),
      namespace: namespace(resource),
      type: ApiVersionKind.resource_type!(resource),
      kube_snapshot_id: snap.id,
      inserted_at: now,
      updated_at: now
    }
  end

  defp raw_addressable_from_resource(resource, now) do
    hash = Hashing.get_hash(resource)
    id = ContentAddressableResource.hash_to_uuid!(hash)

    %{
      value: resource,
      hash: hash,
      id: id,
      inserted_at: now,
      updated_at: now
    }
  end
end
