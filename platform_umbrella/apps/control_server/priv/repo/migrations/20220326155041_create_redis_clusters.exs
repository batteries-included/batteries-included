defmodule ControlServer.Repo.Migrations.CreateFailoverClusters do
  use Ecto.Migration

  def change do
    create table(:redis_clusters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :num_sentinel_instances, :integer
      add :num_redis_instances, :integer

      timestamps(type: :utc_datetime_usec)
    end
  end
end
