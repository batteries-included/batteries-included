defmodule ControlServer.Repo.Migrations.CreateFerretServices do
  use Ecto.Migration

  def change do
    create table(:ferret_services, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string
      add :instances, :integer

      add :cpu_requested, :bigint
      add :cpu_limits, :bigint

      add :memory_requested, :bigint
      add :memory_limits, :bigint

      add :postgres_cluster_id, references(:pg_clusters, on_delete: :delete_all, type: :binary_id)
      add :project_id, references(:system_projects)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ferret_services, [:postgres_cluster_id])
    create unique_index(:ferret_services, [:name])
  end
end
