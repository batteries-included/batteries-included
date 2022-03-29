defmodule HomeBase.Usage.UsageReport do
  @moduledoc """
  The schema for storing UsageReports on the home base side. It includes the
  uuid from the control server so that users can verify.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "usage_reports" do
    field :external_id, Ecto.UUID
    field :generated_at, :utc_datetime_usec
    field :pod_report, :map
    field :node_report, :map
    field :num_nodes, :integer
    field :num_pods, :integer

    belongs_to :billing_report, HomeBase.Billing.BillingReport

    timestamps()
  end

  @doc false
  def changeset(usage_report, attrs) do
    usage_report
    |> cast(attrs, [
      :pod_report,
      :node_report,
      :num_nodes,
      :num_pods,
      :external_id,
      :generated_at
    ])
    |> validate_required([
      :generated_at
    ])
  end
end
