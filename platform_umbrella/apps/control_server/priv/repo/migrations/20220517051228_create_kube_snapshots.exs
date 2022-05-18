defmodule ControlServer.Repo.Migrations.CreateKubeSnapshots do
  use Ecto.Migration

  def change do
    create table(:kube_snapshots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string

      timestamps()
    end
  end
end
