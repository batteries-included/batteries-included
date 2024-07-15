defmodule ControlServer.Repo.Migrations.ChangeProjectReferences do
  use Ecto.Migration

  def up do
    drop constraint(:traditional_services, "traditional_services_project_id_fkey")
    drop constraint(:ferret_services, "ferret_services_project_id_fkey")
    drop constraint(:jupyter_lab_notebooks, "jupyter_lab_notebooks_project_id_fkey")
    drop constraint(:knative_services, "knative_services_project_id_fkey")
    drop constraint(:pg_clusters, "pg_clusters_project_id_fkey")
    drop constraint(:redis_clusters, "redis_clusters_project_id_fkey")

    alter table(:traditional_services) do
      modify :project_id, references(:projects, on_delete: :nilify_all)
    end

    alter table(:ferret_services) do
      modify :project_id, references(:projects, on_delete: :nilify_all)
    end

    alter table(:jupyter_lab_notebooks) do
      modify :project_id, references(:projects, on_delete: :nilify_all)
    end

    alter table(:knative_services) do
      modify :project_id, references(:projects, on_delete: :nilify_all)
    end

    alter table(:pg_clusters) do
      modify :project_id, references(:projects, on_delete: :nilify_all)
    end

    alter table(:redis_clusters) do
      modify :project_id, references(:projects, on_delete: :nilify_all)
    end

    alter table(:ip_address_pools) do
      remove :project_id
    end
  end

  def down do
    drop constraint(:traditional_services, "traditional_services_project_id_fkey")
    drop constraint(:ferret_services, "ferret_services_project_id_fkey")
    drop constraint(:jupyter_lab_notebooks, "jupyter_lab_notebooks_project_id_fkey")
    drop constraint(:knative_services, "knative_services_project_id_fkey")
    drop constraint(:pg_clusters, "pg_clusters_project_id_fkey")
    drop constraint(:redis_clusters, "redis_clusters_project_id_fkey")

    alter table(:traditional_services) do
      modify :project_id, references(:projects, on_delete: :nothing)
    end

    alter table(:ferret_services) do
      modify :project_id, references(:projects, on_delete: :nothing)
    end

    alter table(:jupyter_lab_notebooks) do
      modify :project_id, references(:projects, on_delete: :nothing)
    end

    alter table(:knative_services) do
      modify :project_id, references(:projects, on_delete: :nothing)
    end

    alter table(:pg_clusters) do
      modify :project_id, references(:projects, on_delete: :nothing)
    end

    alter table(:redis_clusters) do
      modify :project_id, references(:projects, on_delete: :nothing)
    end

    alter table(:ip_address_pools) do
      add :project_id, references(:projects, on_delete: :nothing)
    end
  end
end
