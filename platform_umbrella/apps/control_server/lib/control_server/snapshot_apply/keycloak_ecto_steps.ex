defmodule ControlServer.SnapshotApply.KeycloakEctoSteps do
  alias CommonCore.Actions.BaseAction
  alias ControlServer.SnapshotApply.KeycloakSnapshot
  alias CommonCore.Resources.Hashing
  alias ControlServer.ContentAddressable.ContentAddressableResource
  alias Ecto.Multi
  alias ControlServer.Repo

  import ControlServer.SnapshotApply.Keycloak
  import Ecto.Query

  @generation_timeout 60_000

  def create_snap(attrs \\ %{}) do
    create_keycloak_snapshot(attrs)
  end

  @spec snap_generation(ControlServer.SnapshotApply.KeycloakSnapshot.t(), any) :: any
  def snap_generation(%KeycloakSnapshot{} = snap, base_actions) do
    Multi.new()
    |> Multi.run(:addressable_actions, fn _repo, _ ->
      {:ok, addressables_actions(base_actions)}
    end)
    |> Multi.all(
      :existing_hashes,
      fn %{addressable_actions: aa} ->
        # Get the hashes of what's there
        # Allowing us to filter
        aa
        |> Enum.map(fn {_, addressable} -> addressable end)
        |> existing_hashes()
      end
    )
    |> Multi.insert_all(
      :new_addressables,
      ContentAddressableResource,
      fn %{existing_hashes: existing, addressable_actions: aa} = _ctx ->
        set = existing |> List.flatten() |> MapSet.new()

        aa
        |> Enum.map(fn {_, addressable} -> addressable end)
        |> Enum.reject(fn %{hash: hash} -> MapSet.member?(set, hash) end)
      end,
      returning: [:id, :hash]
    )
    |> Multi.insert_all(
      :actions,
      ControlServer.SnapshotApply.KeycloakAction,
      fn %{addressable_actions: aa} ->
        now = DateTime.utc_now()

        Enum.map(aa, fn {base_action, raw_addressable} ->
          raw_action(snap, base_action, raw_addressable, now)
        end)
      end,
      returning: true
    )
    |> Repo.transaction(timeout: @generation_timeout)
  end

  @spec update_snap_status(ControlServer.SnapshotApply.KeycloakSnapshot.t(), any) ::
          {:ok, ControlServer.SnapshotApply.KeycloakSnapshot.t()} | {:error, Ecto.Changeset.t()}
  def update_snap_status(%KeycloakSnapshot{} = snap, status) do
    update_keycloak_snapshot(snap, %{status: status})
  end

  # Given a set of base actions create the inputs that would be used to create
  # content addressable versions of the action value
  #
  # Many of these will not be inserted, so we'
  @spec addressables_actions(list(BaseAction.t())) :: list(map())
  defp addressables_actions(base_actions) do
    # Grab now so that all addressables are created at the same time.
    now = DateTime.utc_now()

    base_actions
    |> Enum.map(fn base_action -> {base_action, raw_addressable(base_action, now)} end)
    # group by id and dedupe
    |> Enum.uniq_by(fn {_, %{hash: hash}} -> hash end)
  end

  defp existing_hashes(addressables) do
    hashes = Enum.map(addressables, & &1.hash)

    from(car in ContentAddressableResource,
      where: car.hash in ^hashes,
      select: [car.hash]
    )
  end

  defp raw_addressable(%BaseAction{} = base_action, now) do
    hash = Hashing.get_hash(base_action.value)
    id = ContentAddressableResource.hash_to_uuid!(hash)

    %{
      value: base_action.value,
      hash: hash,
      id: id,
      inserted_at: now,
      updated_at: now
    }
  end

  defp raw_action(snap, %BaseAction{} = base_action, raw_addressable, now) do
    base_action
    |> Map.from_struct()
    |> Map.drop([:value])
    |> Map.merge(%{
      kube_snapshot_id: snap.id,
      content_addressable_resource_id:
        ContentAddressableResource.hash_to_uuid!(raw_addressable.hash),
      inserted_at: now,
      updated_at: now
    })
  end
end
