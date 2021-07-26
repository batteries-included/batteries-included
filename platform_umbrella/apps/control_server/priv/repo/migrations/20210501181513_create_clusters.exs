defmodule ControlServer.Repo.Migrations.CreateClusters do
  use Ecto.Migration

  def change do
    create table(:clusters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :postgres_version, :string
      add :size, :string
      add :num_instances, :integer

      timestamps(type: :utc_datetime_usec)
    end

    create index(:clusters, [:name], unique: true)
  end
end
