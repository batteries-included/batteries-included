defmodule ControlServer.SnapshotApply.KeycloakEctoSteps do
  @moduledoc false
  import ControlServer.SnapshotApply.Keycloak
  import Ecto.Query

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Resources.Hashing
  alias ControlServer.ContentAddressable.Document
  alias ControlServer.Repo
  alias ControlServer.SnapshotApply.KeycloakAction
  alias ControlServer.SnapshotApply.KeycloakSnapshot
  alias Ecto.Multi

  @generation_timeout 60_000

  def create_snap(attrs \\ %{}) do
    create_keycloak_snapshot(attrs)
  end

  @spec snap_generation(ControlServer.SnapshotApply.KeycloakSnapshot.t(), any) :: any
  def snap_generation(%KeycloakSnapshot{} = snap, base_actions) do
    Multi.new()
    |> Multi.run(:document_actions, fn _repo, _ ->
      {:ok, actions_to_document_args(base_actions)}
    end)
    |> Multi.all(
      :existing_hashes,
      fn %{document_actions: aa} ->
        # Get the hashes of what's there
        # Allowing us to filter
        aa
        |> Enum.map(fn {_, document} -> document end)
        |> existing_hashes()
      end
    )
    |> Multi.insert_all(
      :new_documents,
      Document,
      fn %{existing_hashes: existing, document_actions: aa} = _ctx ->
        set = existing |> List.flatten() |> MapSet.new()

        aa
        |> Enum.map(fn {_, document} -> document end)
        |> Enum.reject(fn %{hash: hash} -> MapSet.member?(set, hash) end)
      end,
      returning: [:id, :hash]
    )
    |> Multi.insert_all(
      :action_insert,
      ControlServer.SnapshotApply.KeycloakAction,
      fn %{document_actions: aa} ->
        now = DateTime.utc_now()

        Enum.map(aa, fn {base_action, raw_document} ->
          action_args(snap, base_action, raw_document, now)
        end)
      end
    )
    |> Multi.all(:actions, fn _ctx ->
      from ka in KeycloakAction,
        where: ka.keycloak_snapshot_id == ^snap.id,
        preload: [:document]
    end)
    |> Repo.transaction(timeout: @generation_timeout)
  end

  @spec update_snap_status(ControlServer.SnapshotApply.KeycloakSnapshot.t(), any) ::
          {:ok, ControlServer.SnapshotApply.KeycloakSnapshot.t()} | {:error, Ecto.Changeset.t()}
  def update_snap_status(%KeycloakSnapshot{} = snap, status) do
    update_keycloak_snapshot(snap, %{status: status})
  end

  def update_actions(actions, updates) do
    actions
    |> Enum.zip(updates)
    |> Enum.reduce(Multi.new(), fn {action, update}, multi ->
      Multi.update(multi, {:action_upadte, action.id}, KeycloakAction.changeset(action, update))
    end)
    |> Repo.transaction(timeout: @generation_timeout)
  end

  # Given a set of base actions create the inputs that would be used to create
  # content document documents of the action value
  #
  # Many of these will not be inserted.
  @spec actions_to_document_args(list(FreshGeneratedAction.t())) :: list(map())
  defp actions_to_document_args(fresh_actions) do
    # Grab now so that all documents are created at the same time.
    now = DateTime.utc_now()

    fresh_actions
    |> Enum.map(fn base_action -> {base_action, document_args(base_action, now)} end)
    # group by id and dedupe
    |> Enum.uniq_by(fn {_, %{hash: hash}} -> hash end)
  end

  defp existing_hashes(documents) do
    hashes = Enum.map(documents, & &1.hash)

    from(car in Document,
      where: car.hash in ^hashes,
      select: [car.hash]
    )
  end

  defp document_args(%FreshGeneratedAction{} = base_action, now) do
    hash = Hashing.get_hash(base_action.value)
    id = Document.hash_to_uuid!(hash)

    %{
      value: base_action.value,
      hash: hash,
      id: id,
      inserted_at: now,
      updated_at: now
    }
  end

  defp action_args(%KeycloakSnapshot{} = snap, %FreshGeneratedAction{} = base_action, raw_document, now) do
    base_action
    |> Map.from_struct()
    |> Map.drop([:value])
    |> Map.merge(%{
      keycloak_snapshot_id: snap.id,
      document_id: Document.hash_to_uuid!(raw_document.hash),
      inserted_at: now,
      updated_at: now
    })
  end
end
