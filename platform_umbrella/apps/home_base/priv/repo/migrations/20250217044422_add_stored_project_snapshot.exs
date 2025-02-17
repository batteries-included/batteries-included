defmodule HomeBase.Repo.Migrations.AddStoredProjectSnapshot do
  use Ecto.Migration

  import Ecto.SoftDelete.Migration

  def change do
    create table(:stored_project_snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :installation_id, references(:installations, on_delete: :nothing, type: :binary_id)
      add :snapshot, :map

      soft_delete_columns()

      timestamps()
    end
  end
end
