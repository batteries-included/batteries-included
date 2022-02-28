defmodule ControlServer.Usage.UsageReport do
  @moduledoc """
  Database backing for usage reports used to determine what's
  running how it's configured and what should be billed.
  """
  use Ecto.Schema
  import Ecto.Changeset

  require Logger

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "usage_reports" do
    field :namespace_report, :map
    field :node_report, :map

    field :num_nodes, :integer
    field :num_pods, :integer

    timestamps()
  end

  @doc false
  def changeset(usage_report, attrs) do
    usage_report
    |> cast(attrs, [:namespace_report, :node_report, :num_nodes, :num_pods])
    |> validate_required([:namespace_report, :num_pods, :num_nodes])
  end
end
