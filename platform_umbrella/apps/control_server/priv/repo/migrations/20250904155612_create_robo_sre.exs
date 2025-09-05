defmodule ControlServer.Repo.Migrations.CreateRoboSRE do
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
      add :parent_issue_id, references(:robo_sre_issues, type: :uuid, on_delete: :delete_all)
      add :resolved_at, :utc_datetime_usec
      add :retry_count, :integer, default: 0, null: false
      add :max_retries, :integer, default: 3, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:robo_sre_issues, [:parent_issue_id])
    create index(:robo_sre_issues, [:subject])
    create index(:robo_sre_issues, [:updated_at])

    create table(:robo_sre_remediation_plans, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :issue_id, references(:robo_sre_issues, type: :uuid, on_delete: :delete_all),
        null: false

      add :retry_delay_ms, :integer, default: 59_000, null: false
      add :success_delay_ms, :integer, default: 30_000, null: false
      add :max_retries, :integer, default: 3, null: false
      add :current_action_index, :integer, default: 0, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:robo_sre_remediation_plans, [:issue_id])

    create table(:robo_sre_actions, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :remediation_plan_id,
          references(:robo_sre_remediation_plans, type: :uuid, on_delete: :delete_all),
          null: false

      add :action_type, :string, null: false
      add :params, :map, default: %{}, null: false
      add :result, :map
      add :executed_at, :utc_datetime_usec
      add :order_index, :integer, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:robo_sre_actions, [:remediation_plan_id])
    create index(:robo_sre_actions, [:remediation_plan_id, :order_index])
  end
end
