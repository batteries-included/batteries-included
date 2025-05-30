defmodule HomeBase.Repo.Migrations.AddVisibilityFlagStoredSnapshot do
  use Ecto.Migration

  def change do
    alter table(:stored_project_snapshots) do
      add :visibility, :string, default: "private", null: false
    end

    create index(:stored_project_snapshots, [:visibility])
    create index(:stored_project_snapshots, [:installation_id, :visibility])
  end
end
