defmodule ControlServer.Repo.Migrations.CreateSystemProjects do
  use Ecto.Migration

  def change do
    create table(:system_projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :type, :string
      add :description, :text

      timestamps(type: :utc_datetime_usec)
    end

    alter table(:pg_clusters) do
      add :project_id, references(:system_projects)
    end

    alter table(:jupyter_lab_notebooks) do
      add :project_id, references(:system_projects)
    end

    alter table(:knative_services) do
      add :project_id, references(:system_projects)
    end

    alter table(:redis_clusters) do
      add :project_id, references(:system_projects)
    end

    alter table(:ceph_clusters) do
      add :project_id, references(:system_projects)
    end

    alter table(:ceph_filesystems) do
      add :project_id, references(:system_projects)
    end
  end
end
