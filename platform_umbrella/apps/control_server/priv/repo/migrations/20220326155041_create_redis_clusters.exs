defmodule ControlServer.Repo.Migrations.CreateFailoverClusters do
  use Ecto.Migration

  def change do
    create table(:redis_clusters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :type, :string, null: false

      add :num_redis_instances, :integer
      add :num_sentinel_instances, :integer
      add :cpu_requested, :integer
      add :cpu_limits, :bigint
      add :memory_requested, :bigint
      add :memory_limits, :bigint

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:redis_clusters, [:type, :name])
  end
end
