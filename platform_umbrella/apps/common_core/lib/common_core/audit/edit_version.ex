defmodule CommonCore.Audit.EditVersion do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "edit_versions" do
    # The patch in Erlang External Term Format
    field :patch, ExAudit.Type.Patch

    field :entity_id, Ecto.UUID

    # name of the table the entity is in
    field :entity_schema, ExAudit.Type.Schema

    # type of the action that has happened to the entity (created, updated, deleted)
    field :action, ExAudit.Type.Action

    # when has this happened
    field :recorded_at, :utc_datetime_usec

    # was this change part of a rollback?
    field :rollback, :boolean, default: false

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:patch, :entity_id, :entity_schema, :action, :recorded_at, :rollback])
  end
end
