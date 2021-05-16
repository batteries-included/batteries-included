defmodule ControlServer.Usage.UsageReport do
  @moduledoc """
  Database backing for usage reports used to determine what's
  running how it's configured and what should be billed.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias ControlServer.Usage.KubeUsage

  @timestamps_opts [type: :utc_datetime_usec]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "usage_reports" do
    field(:namespace_report, :map)
    field(:node_report, :map)
    field(:reported_nodes, :integer)

    timestamps()
  end

  @doc false
  def changeset(usage_report, attrs) do
    usage_report
    |> cast(attrs, [:namespace_report, :node_report, :reported_nodes])
    |> maybe_add_lazy(:namespace_report, &get_namespace_report/1)
    |> maybe_add_lazy(:node_report, &get_node_report/1)
    |> maybe_add_lazy(:reported_nodes, &get_reported_nodes/1)
    |> validate_required([:namespace_report, :node_report, :reported_nodes])
  end

  defp maybe_add_lazy(changeset, field, compute_fun) do
    case get_change(changeset, field) do
      nil ->
        put_change(
          changeset,
          field,
          compute_fun.(changeset)
        )

      _ ->
        changeset
    end
  end

  defp get_namespace_report(_) do
    case KubeUsage.report_namespaces() do
      {:ok, report} ->
        report

      _ ->
        %{}
    end
  end

  defp get_node_report(_) do
    case KubeUsage.report_nodes() do
      {:ok, report} ->
        report

      _ ->
        %{}
    end
  end

  defp get_reported_nodes(changeset) do
    map_size(Map.get(changeset.changes, :namespaces, %{}))
  end
end
