defmodule ControlServer.Repo.Migrations.AddPostgresRestore do
  use Ecto.Migration

  def change do
    alter table(:pg_clusters) do
      add :restore_from_backup, :string
    end
  end
end
