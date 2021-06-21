defmodule KubeUsage.Usage do
  @moduledoc """
  The Usage context.
  """

  import Ecto.Query, warn: false

  alias KubeUsage.Repo
  alias KubeUsage.Usage.UsageReport

  @doc """
  Returns the list of usage_reports.

  ## Examples

      iex> list_usage_reports()
      [%UsageReport{}, ...]

  """
  def list_usage_reports do
    Repo.all(UsageReport)
  end

  @doc """
  Gets a single usage_report.

  Raises `Ecto.NoResultsError` if the Usage report does not exist.

  ## Examples

      iex> get_usage_report!(123)
      %UsageReport{}

      iex> get_usage_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_usage_report!(id), do: Repo.get!(UsageReport, id)

  @doc """
  Creates a usage_report.

  ## Examples

      iex> create_usage_report(%{field: value})
      {:ok, %UsageReport{}}

      iex> create_usage_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_usage_report(attrs \\ %{}) do
    %UsageReport{}
    |> UsageReport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a usage_report.

  ## Examples

      iex> update_usage_report(usage_report, %{field: new_value})
      {:ok, %UsageReport{}}

      iex> update_usage_report(usage_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_usage_report(%UsageReport{} = usage_report, attrs) do
    usage_report
    |> UsageReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a usage_report.

  ## Examples

      iex> delete_usage_report(usage_report)
      {:ok, %UsageReport{}}

      iex> delete_usage_report(usage_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_usage_report(%UsageReport{} = usage_report) do
    Repo.delete(usage_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking usage_report changes.

  ## Examples

      iex> change_usage_report(usage_report)
      %Ecto.Changeset{data: %UsageReport{}}

  """
  def change_usage_report(%UsageReport{} = usage_report, attrs \\ %{}) do
    UsageReport.changeset(usage_report, attrs)
  end
end
