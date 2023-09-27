defmodule ControlServer.Repo.Migrations.CreateClusters do
  use Ecto.Migration

  def change do
    create table(:pg_clusters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :postgres_version, :string
      add :storage_size, :bigint
      add :storage_class, :string
      add :cpu_requested, :integer
      add :cpu_limits, :integer
      add :memory_requested, :bigint
      add :memory_limits, :bigint
      add :num_instances, :integer
      add :type, :string
      add :team_name, :string
      add :users, :map
      add :databases, :map

      add :credential_copies, :map

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:pg_clusters, [:type, :team_name, :name])
  end
end
