defmodule HomeBase.Repo.Migrations.AddBillingReportToUsage do
  use Ecto.Migration

  def change do
    alter table(:usage_reports) do
      add :billing_report_id, references(:billing_reports, on_delete: :nilify_all)
    end
  end
end
