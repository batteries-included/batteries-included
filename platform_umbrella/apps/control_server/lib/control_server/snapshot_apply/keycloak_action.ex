defmodule ControlServer.SnapshotApply.KeycloakAction do
  use TypedEctoSchema
  import Ecto.Changeset
  alias Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @required_fields [:action, :type]
  @optional_fields [
    :realm,
    :is_success,
    :apply_result,
    :document_id,
    :keycloak_snapshot_id
  ]

  typed_schema "keycloak_actions" do
    # What we're trying to do.
    # For right now since fields are not always included
    # we're not going to handle sync
    #
    # Delete and sync might need a identifier field
    field :action, Ecto.Enum, values: [:create, :sync, :delete]

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

  def changeset(keycloak_action, attrs) do
    keycloak_action
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_realm_present_if_needed()
  end

  @spec validate_realm_present_if_needed(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_realm_present_if_needed(%Changeset{} = changeset) do
    # given an ecto changeset with fields type and realm
    # for all values of the field :type except for :realm
    # validate the field realm is required.
    action_type = Ecto.Changeset.get_field(changeset, :type, nil)
    validate_realm_with_type(changeset, action_type)
  end

  def validate_realm_with_type(changeset, :realm), do: changeset
  def validate_realm_with_type(changeset, "realm"), do: changeset

  def validate_realm_with_type(changeset, _) do
    validate_required(changeset, [:realm],
      message: "realm is required for all types other than realm itself"
    )
  end
end
