defmodule ControlServer.Repo.Migrations.RemoveProjectType do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      remove :type
    end
  end
end
