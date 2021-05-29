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

    field :by_hour, :map

    field :node_hours, :integer
    field :pod_hours, :integer

    field :stripe_subscription_id, :binary_id

    has_many :usage_reports, HomeBase.Usage.UsageReport

    timestamps()
  end

  @doc false
  def changeset(billing_report, attrs) do
    billing_report
    |> cast(attrs, [:start, :end, :node_hours, :pod_hours, :by_hour])
    |> validate_required([:start, :end, :by_hour, :pod_hours])
  end
end
