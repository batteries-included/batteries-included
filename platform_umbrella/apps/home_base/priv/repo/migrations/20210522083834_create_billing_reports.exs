defmodule HomeBase.Repo.Migrations.CreateBillingReports do
  use Ecto.Migration

  def change do
    create table(:billing_reports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :start, :utc_datetime_usec
      add :end, :utc_datetime_usec
      add :total_node_hours, :integer
      add :node_by_hour, :map

      add :stripe_subscription_id,
          references(:stripe_subscriptions, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:billing_reports, [:stripe_subscription_id])
  end
end
