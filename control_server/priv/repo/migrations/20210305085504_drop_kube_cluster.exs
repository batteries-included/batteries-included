defmodule Server.Repo.Migrations.DropKubeCluster do
  use Ecto.Migration

  def change do
    drop index(:raw_configs, [:kube_cluster_id])

    alter table(:raw_configs) do
      remove :kube_cluster_id
    end

    drop table(:kube_clusters)
  end
end
