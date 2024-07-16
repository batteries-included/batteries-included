defmodule ControlServer.Repo.Migrations.AddTraditionalServicesProject do
  use Ecto.Migration

  def change do
    alter table(:traditional_services) do
      add :project_id, references(:projects)
    end
  end
end
