defmodule HomeBase.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias HomeBase.Billing.BillingReport
  alias HomeBase.Repo
  alias HomeBase.Usage

  require Logger

  @doc """
  Returns the list of billing_reports.

  ## Examples

      iex> HomeBase.Billing.list_billing_reports()
      [%HomeBase.Billing.BillingReport{} ]

  """
  def list_billing_reports do
    Repo.all(BillingReport)
  end

  @doc """
  Gets a single billing_report.

  Raises `Ecto.NoResultsError` if the Billing report does not exist.

  ## Examples

      iex> HomeBase.Billing.get_billing_report!(123)
      %HomeBase.Billing.BillingReport{}

      iex> HomeBase.Billing.get_billing_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_billing_report!(id), do: Repo.get!(BillingReport, id)

  def get_billing_report_pre(id) do
    BillingReport |> Repo.get(id) |> Repo.preload(:usage_reports)
  end

  @doc """
  Creates a billing_report.

  ## Examples

      iex> HomeBase.Billing.create_billing_report(%{node_hours: 100, pod_hours: 200})
      {:ok, %HomeBase.Billing.BillingReport{}}

      iex> HomeBase.Billing.create_billing_report(%{field: "bad_value"})
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

      iex> HomeBase.Billing.update_billing_report(%{}, %{node_hours: 100})
      {:ok, %HomeBase.Billing.BillingReport{}}

      iex> HomeBase.Billing.update_billing_report(%{}, %{field: "bad_value})
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

      iex> HomeBase.Billing.delete_billing_report(billing_report)
      {:ok, %HomeBase.Billing.BillingReport{}}

      iex> HomeBase.Billing.delete_billing_report(billing_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_billing_report(%BillingReport{} = billing_report) do
    Repo.delete(billing_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking billing_report changes.

  ## Examples

      iex> HomeBase.Billing.change_billing_report(billing_report)
      %Ecto.Changeset{data: %HomeBase.Billing.BillingReport{}}

  """
  def change_billing_report(%BillingReport{} = billing_report, attrs \\ %{}) do
    BillingReport.changeset(billing_report, attrs)
  end

  @doc """

  ## Examples
      iex> HomeBase.Billing.generate_billing_report(DateTime.utc_now)
      {:ok, %{}}
  """
  def generate_billing_report(end_report_time) do
    end_report_time = HomeBase.Time.truncate(end_report_time, :hour)

    # since this is all about billing all of this is in a giant transaction. This all
    # works or nothing works.
    #
    Multi.new()
    # Get  when the last time there was a
    # billing report generated. We need that billing report's
    # end time. It will become the start time of this new billing report
    |> Multi.run(:last_end, &last_billing_end/2)
    # Get a mapping of some hour time span with value of
    # the maximum number of reported nodes. This map will
    # be the basis of the billing report.
    #
    # It powers the charts and the final billed node value
    # is the sum of all values in this map.
    |> Multi.run(:by_hour, fn repo, %{last_end: begin_report_time} ->
      # Before doing any of that make sure that the time range isn't invalid.
      #
      # TODO this should be a function above choosing a valid range if possible. That also
      # solves monthly. We'll change the end to be the last of the month. However that's
      # fun math with times. so punt for now.
      if begin_report_time >= end_report_time do
        {:error, :begin_before_end}
      else
        # The range of time
        {begin_report_time, end_report_time}
        # Add on the same filter used everywhere to ensure everything is done consistently
        |> Usage.generated_within()
        # Add on the group by and summation
        |> reported_usaged_by_hour()
        # Run the query
        |> repo.all()
        # Then map it into a format that's useful in json and elixir.
        |> to_hour_map()
      end
    end)
    |> Multi.insert(:billing_report, fn %{
                                          last_end: begin_report_time,
                                          by_hour: by_hour
                                        } ->
      # Finally compute the total billing count.
      total_nodes = total_report_field(by_hour, :num_nodes)
      total_pods = total_report_field(by_hour, :num_pods)

      BillingReport.changeset(%BillingReport{}, %{
        start: begin_report_time,
        end: end_report_time,
        by_hour: by_hour,
        node_hours: total_nodes,
        pod_hours: total_pods
      })
    end)
    |> Multi.update_all(
      :update_all,
      fn %{billing_report: billing_report} ->
        # Now all usage reports that we used to generated this are
        # owned by the new billing report as proof of what went into it. We should be
        # able to walk backwards from this is what your cluster saw in your datatabase to
        # here's what we saw per minute, to here's why we billed you this many hours.
        {billing_report.start, billing_report.end}
        |> Usage.generated_within()
        |> update(set: [billing_report_id: ^billing_report.id])
      end,
      []
    )
    |> Repo.transaction()
  end

  defp total_report_field(by_hour, _field) when map_size(by_hour) == 0, do: 0

  defp total_report_field(by_hour, field) do
    Enum.reduce(by_hour, 0, fn {_, m}, acc -> acc + Map.get(m, field, 0) end)
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

  defp reported_usaged_by_hour(query) do
    query
    |> select([ur],
      num_nodes: max(ur.num_nodes),
      num_pods: max(ur.num_pods),
      generated_hour:
        fragment(
          "date_trunc(?, ?) as generated_hour",
          "hour",
          ur.generated_at
        )
    )
    |> group_by([fragment("generated_hour")])
    |> order_by([fragment("generated_hour")])
  end

  defp to_hour_map(results) do
    {:ok, results |> Enum.map(&generated_hour_to_key/1) |> Map.new()}
  end

  def generated_hour_to_key(m) do
    forced_map = Map.new(m)
    {Map.get(forced_map, :generated_hour), forced_map}
  end
end
