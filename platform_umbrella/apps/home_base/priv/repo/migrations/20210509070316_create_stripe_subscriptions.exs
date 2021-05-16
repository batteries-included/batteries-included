defmodule HomeBase.Repo.Migrations.CreateStripeSubscriptions do
  use Ecto.Migration

  def change do
    create table(:stripe_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :company, :string
      add :stripe_subscription_id, :string

      timestamps(type: :utc_datetime_usec)
    end
  end
end
