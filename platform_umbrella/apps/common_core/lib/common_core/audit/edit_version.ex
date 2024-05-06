defmodule CommonCore.Audit.EditVersion do
  @moduledoc false

  use TypedEctoSchema

  import Ecto.Changeset

  # We can't use the standard CommonCore schema
  # because EditVersions are inserted via a backround
  # tranasacion. That transaction relies on the :binary_id
  # autogeneration behavior. (:id and :binary_id delegate
  # to the database adapter for generation)
  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime_usec]

  @derive {Jason.Encoder, except: [:__meta__]}

  @optional_fields ~w(rollback)a
  @required_fields ~w(patch entity_id entity_schema action recorded_at)a

  typed_schema "edit_versions" do
    # The patch in Erlang External Term Format
    field :patch, ExAudit.Type.Patch

    field :entity_id, CommonCore.Util.BatteryUUID

    # name of the table the entity is in
    field :entity_schema, ExAudit.Type.Schema

    # type of the action that has happened to the entity (created, updated, deleted)
    field :action, ExAudit.Type.Action

    # when has this happened
    field :recorded_at, :utc_datetime_usec

    # was this change part of a rollback?
    field :rollback, :boolean, default: false
  end

  def changeset(struct, params \\ %{}) do
    fields = Enum.concat(@required_fields, @optional_fields)

    struct
    |> cast(params, fields)
    |> validate_required(@required_fields)
  end
end
