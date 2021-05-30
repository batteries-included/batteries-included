defmodule HomeBase.Repo.Migrations.AddIndexUsageReportGenerated do
  use Ecto.Migration

  def change do
    create index(:usage_reports, [:generated_at])
  end
end
