defmodule HomeBase.Repo.Migrations.AddInstallationOwners do
  use Ecto.Migration

  def change do
    alter table(:installations) do
      add :user_id, references(:users, type: :binary_id, on_delete: :restrict)
      add :team_id, references(:teams, type: :binary_id, on_delete: :restrict)
    end
  end
end
