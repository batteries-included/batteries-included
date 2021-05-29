defmodule HomeBase.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias HomeBase.Billing.BillingReport
  alias HomeBase.Repo
  alias HomeBase.Usage.UsageReport

  @doc """
  Returns the list of billing_reports.

  ## Examples

      iex> list_billing_reports()
      [%BillingReport{}, ...]

  """
  def list_billing_reports do
    Repo.all(BillingReport)
  end

  @doc """
  Gets a single billing_report.

  Raises `Ecto.NoResultsError` if the Billing report does not exist.

  ## Examples

      iex> get_billing_report!(123)
      %BillingReport{}

      iex> get_billing_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_billing_report!(id), do: Repo.get!(BillingReport, id)

  @doc """
  Creates a billing_report.

  ## Examples

      iex> create_billing_report(%{field: value})
      {:ok, %BillingReport{}}

      iex> create_billing_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_billing_report(attrs \\ %{}) do
    %BillingReport{}
    |> BillingReport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a billing_report.

  ## Examples

      iex> update_billing_report(billing_report, %{field: new_value})
      {:ok, %BillingReport{}}

      iex> update_billing_report(billing_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_billing_report(%BillingReport{} = billing_report, attrs) do
    billing_report
    |> BillingReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a billing_report.

  ## Examples

      iex> delete_billing_report(billing_report)
      {:ok, %BillingReport{}}

      iex> delete_billing_report(billing_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_billing_report(%BillingReport{} = billing_report) do
    Repo.delete(billing_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking billing_report changes.

  ## Examples

      iex> change_billing_report(billing_report)
      %Ecto.Changeset{data: %BillingReport{}}

  """
  def change_billing_report(%BillingReport{} = billing_report, attrs \\ %{}) do
    BillingReport.changeset(billing_report, attrs)
  end

  def generate_billing_report(end_report_time) do
    end_report_time = HomeBase.Time.truncate(end_report_time, :hour)

    Multi.new()
    |> Multi.run(:last_end, &last_billing_end/2)
    |> Multi.run(:count_map, fn repo, %{last_end: begin_report_time} ->
      if begin_report_time >= end_report_time do
        {:error, :begin_before_end}
      else
        {begin_report_time, end_report_time} |> select_by_hour() |> repo.all() |> to_hour_map()
      end
    end)
    |> Multi.insert(:billing_report, fn %{last_end: begin_report_time, count_map: count_map} ->
      total =
        count_map
        |> Map.to_list()
        |> Enum.reduce(0, fn {_hr, m}, acc -> acc + Map.get(m, :reported_nodes, 0) end)

      BillingReport.changeset(%BillingReport{}, %{
        start: begin_report_time,
        end: end_report_time,
        node_by_hour: count_map,
        total_node_hours: total
      })
    end)
    |> Repo.transaction()
  end

  defp last_billing_report(repo) do
    repo.one(from BillingReport, order_by: [desc: :end], limit: 1)
  end

  defp last_billing_end(repo, _) do
    case last_billing_report(repo) do
      nil ->
        DateTime.from_unix(0)

      br ->
        {:ok, br.end}
    end
  end

  defp select_by_hour({begin_report_time, end_report_time}) do
    from ur in UsageReport,
      where: ur.generated_at > ^begin_report_time and ur.generated_at <= ^end_report_time,
      select: %{
        reported_nodes: max(ur.reported_nodes),
        generated_hour:
          fragment(
            "date_trunc(?, ?) as generated_hour",
            "hour",
            ur.generated_at
          )
      },
      group_by: [fragment("generated_hour")],
      order_by: [fragment("generated_hour")]
  end

  defp to_hour_map(results) do
    {:ok, results |> Enum.map(&to_tuple/1) |> Map.new()}
  end

  defp to_tuple(%{generated_hour: gh} = m) do
    {gh, m}
  end
end
