defmodule HomeBase.ET do
  @moduledoc """
  The ET context.
  """

  import Ecto.Query, warn: false

  alias HomeBase.ET.StoredUsageReport
  alias HomeBase.Repo

  @doc """
  Returns the list of stored_usage_reports.

  ## Examples

      iex> list_stored_usage_reports()
      [%StoredUsageReport{}, ...]

  """
  def list_stored_usage_reports do
    Repo.all(StoredUsageReport)
  end

  @doc """
  Gets a single stored_usage_report.

  Raises `Ecto.NoResultsError` if the Stored usage report does not exist.

  ## Examples

      iex> get_stored_usage_report!(123)
      %StoredUsageReport{}

      iex> get_stored_usage_report!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stored_usage_report!(id), do: Repo.get!(StoredUsageReport, id)

  @doc """
  Creates a stored_usage_report.

  ## Examples

      iex> create_stored_usage_report(%{field: value})
      {:ok, %StoredUsageReport{}}

      iex> create_stored_usage_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stored_usage_report(attrs \\ %{}) do
    %StoredUsageReport{}
    |> StoredUsageReport.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stored_usage_report.

  ## Examples

      iex> update_stored_usage_report(stored_usage_report, %{field: new_value})
      {:ok, %StoredUsageReport{}}

      iex> update_stored_usage_report(stored_usage_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stored_usage_report(%StoredUsageReport{} = stored_usage_report, attrs) do
    stored_usage_report
    |> StoredUsageReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stored_usage_report.

  ## Examples

      iex> delete_stored_usage_report(stored_usage_report)
      {:ok, %StoredUsageReport{}}

      iex> delete_stored_usage_report(stored_usage_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stored_usage_report(%StoredUsageReport{} = stored_usage_report) do
    Repo.delete(stored_usage_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stored_usage_report changes.

  ## Examples

      iex> change_stored_usage_report(stored_usage_report)
      %Ecto.Changeset{data: %StoredUsageReport{}}

  """
  def change_stored_usage_report(%StoredUsageReport{} = stored_usage_report, attrs \\ %{}) do
    StoredUsageReport.changeset(stored_usage_report, attrs)
  end
end