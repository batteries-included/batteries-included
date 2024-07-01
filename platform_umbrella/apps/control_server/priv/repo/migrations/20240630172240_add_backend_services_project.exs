defmodule ControlServer.Repo.Migrations.AddBackendServicesProject do
  use Ecto.Migration

  def change do
    alter table(:backend_services) do
      add :project_id, references(:projects)
    end
  end
end
