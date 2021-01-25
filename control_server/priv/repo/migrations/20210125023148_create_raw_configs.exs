defmodule Server.Repo.Migrations.CreateRawConfigs do
  use Ecto.Migration

  def change do
    create table(:raw_configs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string
      add :content, :map
      add :kube_cluster_id, references(:kube_clusters, on_delete: :nilify_all, type: :uuid)

      timestamps()
    end

    create index(:raw_configs, [:kube_cluster_id])
  end
end
