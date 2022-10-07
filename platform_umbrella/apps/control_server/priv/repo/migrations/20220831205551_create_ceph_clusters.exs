defmodule ControlServer.Repo.Migrations.CreateCephCluster do
  use Ecto.Migration

  def change do
    create table(:ceph_clusters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :namespace, :string, default: "battery-data"
      add :num_mon, :integer, default: 1, null: false
      add :num_mgr, :integer, default: 1, null: false
      add :nodes, :map
      add :data_dir_host_path, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ceph_clusters, [:name])
    create unique_index(:ceph_clusters, [:namespace])
  end
end
