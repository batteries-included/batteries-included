defmodule HomeBase.Repo.Migrations.CreateUsageReports do
  use Ecto.Migration

  def change do
    create table(:usage_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :namespace_report, :map
      add :node_report, :map
      add :num_nodes, :integer
      add :num_pods, :integer
      add :external_id, :uuid
      add :generated_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end
  end
end
