defmodule ControlServer.Repo.Migrations.RenameSystemProjects do
  use Ecto.Migration

  def change do
    rename table(:system_projects), to: table(:projects)
  end
end
