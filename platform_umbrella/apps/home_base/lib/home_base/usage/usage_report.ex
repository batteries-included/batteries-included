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
    field(:external_id, Ecto.UUID)
    field(:generated_at, :utc_datetime)
    field(:namespace_report, :map)
    field(:node_report, :map)
    field(:reported_nodes, :integer)

    timestamps()
  end

  @doc false
  def changeset(usage_report, attrs) do
    usage_report
    |> cast(attrs, [:namespace_report, :node_report, :reported_nodes, :external_id, :generated_at])
    |> validate_required([
      :namespace_report,
      :reported_nodes,
      :external_id,
      :generated_at
    ])
  end
end
