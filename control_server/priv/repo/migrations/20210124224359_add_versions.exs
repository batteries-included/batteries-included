defmodule Repo.Migrations.AddVersions do
  use Ecto.Migration

  def change do
    create table(:versions) do
      add :event, :string, null: false, size: 10
      add :item_type, :string, null: false
      add :item_id, :binary_id
      add :item_changes, :map, null: false

      # add :originator_id, references(:users) # you can change :users to your own foreign key constraint
      add :origin, :string, size: 50
      add :meta, :map

      # Configure timestamps type in config.ex :paper_trail :timestamps_type
      add :inserted_at, :utc_datetime, null: false
    end

    create index(:versions, [:item_id, :item_type])
  end
end
