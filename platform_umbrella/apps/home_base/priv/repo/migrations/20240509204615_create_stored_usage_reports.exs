defmodule HomeBase.Repo.Migrations.CreateStoredUsageReports do
  use Ecto.Migration

  def change do
    create table(:stored_usage_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :report, :map
      add :installation_id, references(:installations, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:stored_usage_reports, [:installation_id])
  end
end
