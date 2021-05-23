defmodule HomeBase.Billing.BillingReport do
  @moduledoc """
  The schema that holds data about actual billing hours right before they are reported.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "billing_reports" do
    field :end, :utc_datetime_usec
    field :start, :utc_datetime_usec

    field :node_by_hour, :map

    field :total_node_hours, :integer
    field :stripe_subscription_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(billing_report, attrs) do
    billing_report
    |> cast(attrs, [:start, :end, :total_node_hours, :node_by_hour])
    |> validate_required([:start, :end, :total_node_hours, :node_by_hour])
  end
end
