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

    field(:num_nodes, :integer)
    field(:num_pods, :integer)

    timestamps()
  end

  @doc false
  def changeset(usage_report, attrs) do
    usage_report
    |> cast(attrs, [:namespace_report, :node_report, :num_nodes, :num_pods])
    |> maybe_add_lazy(:namespace_report, &get_namespace_report/1)
    |> maybe_add_lazy(:node_report, &get_node_report/1)
    |> maybe_add_lazy(:num_nodes, &get_num_nodes/1)
    |> maybe_add_lazy(:num_pods, &get_num_pods/1)
    |> validate_required([:namespace_report, :num_pods])
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

  defp get_num_nodes(changeset) do
    length(
      changeset.changes
      |> Map.get(:namespace_report, %{})
      |> Enum.flat_map(fn {_ns, pod_list} -> Enum.map(pod_list, &get_node_name/1) end)
      |> Enum.uniq()
    )
  end

  defp get_node_name(pod), do: get_in(pod, ["spec", "nodeName"])

  defp get_num_pods(changeset) do
    changeset.changes
    |> Map.get(:namespace_report, %{})
    |> Enum.map(fn {_ns, pod_list} -> length(pod_list) end)
    |> Enum.reduce(0, fn x, acc -> x + acc end)
  end
end
