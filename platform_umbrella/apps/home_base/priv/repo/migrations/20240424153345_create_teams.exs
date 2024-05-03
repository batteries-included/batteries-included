defmodule HomeBase.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :citext, null: false
      add :op_email, :citext

      timestamps()
    end

    create table(:teams_roles, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :is_admin, :boolean, null: false
      add :invited_email, :citext
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :team_id, references(:teams, type: :binary_id, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:teams_roles, [:user_id, :team_id])
    create unique_index(:teams_roles, [:invited_email, :team_id])
    create index(:teams_roles, [:team_id])
  end
end
