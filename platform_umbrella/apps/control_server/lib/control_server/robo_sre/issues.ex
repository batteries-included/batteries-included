defmodule ControlServer.RoboSRE.Issues do
  @moduledoc """
  The RoboSRE context for managing issues detected and remediated by the automated system.
  """

  use ControlServer, :context

  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.RoboSRE.Issue
  alias EventCenter.Database, as: DatabaseEventCenter

  @spec list_issues() :: list(Issue.t())
  @doc """
  Returns the list of issues.

  ## Examples

      iex> list_issues()
      [%Issue{}, ...]

  """
  def list_issues do
    Repo.all(Issue)
  end

  @spec list_issues(map()) :: {:ok, {[Issue.t()], Flop.Meta.t()}} | {:error, Flop.Meta.t()}
  @doc """
  Returns a paginated list of issues with filtering and sorting.

  ## Examples

      iex> list_issues(%{limit: 10, offset: 0})
      {:ok, {[%Issue{}], %Flop.Meta{}}}

  """
  def list_issues(params) do
    Repo.Flop.validate_and_run(Issue, params, for: Issue)
  end

  def list_open_issues do
    Repo.all(
      from(i in Issue,
        where: i.status in [:detected, :analyzing, :planning, :remediating, :verifying],
        order_by: [desc: :inserted_at]
      )
    )
  end

  @spec get_issue!(BatteryUUID.t(), keyword()) :: Issue.t()
  @doc """
  Gets a single issue.

  Raises `Ecto.NoResultsError` if the Issue does not exist.

  ## Examples

      iex> get_issue!("batt_123")
      %Issue{}

      iex> get_issue!("batt_456")
      ** (Ecto.NoResultsError)

  """
  def get_issue!(id, opts \\ []) do
    Issue
    |> preload(^Keyword.get(opts, :preload, []))
    |> Repo.get!(id)
  end

  @spec get_issue(BatteryUUID.t(), keyword()) :: Issue.t() | nil
  @doc """
  Gets a single issue, returning nil if not found.
  """
  def get_issue(id, opts \\ []) do
    Issue
    |> preload(^Keyword.get(opts, :preload, []))
    |> Repo.get(id)
  end

  @spec create_issue(map()) :: {:ok, Issue.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Creates an issue.

  ## Examples

      iex> create_issue(%{subject: "cluster.pod.my-app", issue_type: :pod_crash})
      {:ok, %Issue{}}

      iex> create_issue(%{subject: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def create_issue(attrs \\ %{}) do
    %Issue{}
    |> Issue.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:insert)
  end

  @spec update_issue(Issue.t(), map()) :: {:ok, Issue.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Updates an issue.

  ## Examples

      iex> update_issue(issue, %{status: :resolved})
      {:ok, %Issue{}}

      iex> update_issue(issue, %{subject: "invalid"})
      {:error, %Ecto.Changeset{}}

  """
  def update_issue(%Issue{} = issue, attrs) do
    issue
    |> Issue.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @spec delete_issue(Issue.t()) :: {:ok, Issue.t()} | {:error, Ecto.Changeset.t()}
  @doc """
  Deletes an issue.

  ## Examples

      iex> delete_issue(issue)
      {:ok, %Issue{}}

      iex> delete_issue(issue)
      {:error, %Ecto.Changeset{}}

  """
  def delete_issue(%Issue{} = issue) do
    issue
    |> Repo.delete()
    |> broadcast(:delete)
  end

  @spec change_issue(Issue.t(), map()) :: Ecto.Changeset.t()
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue changes.

  ## Examples

      iex> change_issue(issue)
      %Ecto.Changeset{data: %Issue{}}

  """
  def change_issue(%Issue{} = issue, attrs \\ %{}) do
    Issue.changeset(issue, attrs)
  end

  @spec find_open_issues_by_subject(String.t()) :: [Issue.t()]
  @doc """
  Find all open issues for a given subject.
  """
  def find_open_issues_by_subject(subject) do
    Repo.all(
      from(i in Issue,
        where: i.subject == ^subject,
        where: i.status in [:detected, :analyzing, :planning, :remediating, :verifying]
      )
    )
  end

  @spec find_issues_by_parent(BatteryUUID.t()) :: [Issue.t()]
  @doc """
  Find all child issues for a given parent issue.
  """
  def find_issues_by_parent(parent_id) do
    Repo.all(
      from(i in Issue,
        where: i.parent_issue_id == ^parent_id,
        order_by: [desc: :inserted_at]
      )
    )
  end

  @spec count_open_issues() :: integer()
  @doc """
  Count all open issues.
  """
  def count_open_issues do
    Repo.one(
      from(i in Issue,
        where: i.status in [:detected, :analyzing, :planning, :remediating, :verifying],
        select: count(i.id)
      )
    )
  end

  @spec mark_stale_issues_as_resolved(integer()) :: {integer(), nil}
  @doc """
  Mark issues as resolved if they haven't been seen for the given number of hours.
  """
  def mark_stale_issues_as_resolved(hours_stale \\ 24) do
    cutoff = DateTime.add(DateTime.utc_now(), -hours_stale, :hour)

    Repo.update_all(
      from(i in Issue,
        where: i.status in [:detected, :analyzing, :planning, :remediating, :verifying],
        where: i.updated_at < ^cutoff
      ),
      set: [status: :resolved, resolved_at: DateTime.utc_now()]
    )
  end

  # Private functions

  defp broadcast({:ok, issue} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:issue, action, issue)
    result
  end

  defp broadcast(result, _action), do: result
end
