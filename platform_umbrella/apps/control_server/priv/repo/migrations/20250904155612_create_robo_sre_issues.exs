defmodule ControlServer.Repo.Migrations.CreateRoboSreIssues do
  use Ecto.Migration

  def change do
    create table(:robo_sre_issues, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :subject, :string, null: false
      add :subject_type, :string, null: false
      add :issue_type, :string, null: false
      add :trigger, :string, null: false
      add :trigger_params, :map, default: %{}
      add :status, :string, null: false, default: "detected"
      add :handler, :string
      add :handler_state, :map, default: %{}
      add :parent_issue_id, references(:robo_sre_issues, type: :uuid, on_delete: :delete_all)
      add :resolved_at, :utc_datetime_usec
      add :retry_count, :integer, default: 0, null: false
      add :max_retries, :integer, default: 3, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:robo_sre_issues, [:parent_issue_id])
    create index(:robo_sre_issues, [:subject])
    create index(:robo_sre_issues, [:updated_at])
  end
end
