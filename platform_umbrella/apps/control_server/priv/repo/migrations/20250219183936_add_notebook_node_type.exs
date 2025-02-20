defmodule ControlServer.Repo.Migrations.AddNotebookNodeType do
  use Ecto.Migration

  def change do
    alter table(:jupyter_lab_notebooks) do
      add :node_type, :string
    end
  end
end
