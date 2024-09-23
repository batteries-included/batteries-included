defmodule ControlServer.SnapshotApply.KeycloakAction do
  @moduledoc false

  use CommonCore, :schema

  @required_fields [:action, :type]

  batt_schema "keycloak_actions" do
    # What we're trying to do.
    # For right now since fields are not always included
    # we're not going to handle sync
    #
    # Delete and sync might need a identifier field
    field :action, Ecto.Enum, values: [:create, :sync, :delete, :ping]

    # What we're trying to create
    field :type, Ecto.Enum, values: [:realm, :client, :user]

    # The owning realm
    field :realm, :string

    # What happended to this in the end
    field :is_success, :boolean

    # The reaso
    field :apply_result, :string

    # The contents of what we are trying to push
    belongs_to :document, ControlServer.ContentAddressable.Document

    # The snapshot this action is a part of.
    belongs_to :keycloak_snapshot, ControlServer.SnapshotApply.KeycloakSnapshot

    timestamps()
  end

  def changeset(keycloak_action, attrs, opts \\ []) do
    keycloak_action
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> validate_realm_present_if_needed()
    |> validate_ping_only_for_realm()
  end

  @spec validate_realm_present_if_needed(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_realm_present_if_needed(%Ecto.Changeset{} = changeset) do
    # given an ecto changeset with fields type and realm
    # for all values of the field :type except for :realm
    # validate the field realm is required.
    action_type = get_field(changeset, :type, nil)
    validate_realm_with_type(changeset, action_type)
  end

  defp validate_realm_with_type(changeset, :realm), do: changeset
  defp validate_realm_with_type(changeset, "realm"), do: changeset

  defp validate_realm_with_type(changeset, _) do
    validate_required(changeset, [:realm], message: "realm is required for all types other than realm itself")
  end

  @spec validate_ping_only_for_realm(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_ping_only_for_realm(changeset) do
    action = get_field(changeset, :type, nil)
    validate_ping_with_action(changeset, action)
  end

  # ping is only valid when the type is realm
  defp validate_ping_with_action(cs, :ping), do: validate_inclusion(cs, :type, [:realm])
  defp validate_ping_with_action(cs, "ping"), do: validate_inclusion(cs, :type, [:realm])
  defp validate_ping_with_action(cs, _), do: cs
end
