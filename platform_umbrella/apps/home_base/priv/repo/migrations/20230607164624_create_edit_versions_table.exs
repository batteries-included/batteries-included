defmodule HomeBase.Repo.Migrations.CreateEditVersionsTable do
  use Ecto.Migration

  def change do
    create table(:edit_versions, primary_key: false) do
      add :id, :uuid, primary_key: true

      # The patch in Erlang External Term Format
      add :patch, :binary

      add :entity_id, :uuid

      # name of the table the entity is in
      add :entity_schema, :string

      # type of the action that has happened to the entity (created, updated, deleted)
      add :action, :string

      # when has this happened
      add :recorded_at, :utc_datetime_usec

      # was this change part of a rollback?
      add :rollback, :boolean, default: false
    end

    create index(:edit_versions, [:entity_schema, :entity_id])
  end
end
