defmodule ControlServer.Repo.Migrations.AddNotebookEnvVars do
  use Ecto.Migration

  def change do
    alter table(:jupyter_lab_notebooks) do
      add :env_values, :map
    end
  end
end
