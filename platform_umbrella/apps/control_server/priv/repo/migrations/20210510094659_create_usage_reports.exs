defmodule ControlServer.Repo.Migrations.CreateUsageReports do
  use Ecto.Migration

  def change do
    create table(:usage_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :namespace_report, :map
      add :node_report, :map
      add :reported_nodes, :integer

      timestamps(type: :utc_datetime_usec)
    end
  end
end
