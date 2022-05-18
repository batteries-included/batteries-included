defmodule ControlServer.Repo.Migrations.CreateResourcePaths do
  use Ecto.Migration

  def change do
    create table(:resource_paths, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string
      add :resource_value, :map
      add :hash, :string
      add :is_success, :boolean
      add :apply_result, :string

      add :kube_snapshot_id,
          references(:kube_snapshots, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:resource_paths, [:kube_snapshot_id])
  end
end
