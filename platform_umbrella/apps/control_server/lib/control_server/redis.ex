defmodule ControlServer.Redis do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.Redis.FailoverCluster
  alias EventCenter.Database, as: DatabaseEventCenter

  @doc """
  Returns the list of failover_clusters.

  ## Examples

      iex> list_failover_clusters()
      [%FailoverCluster{}, ...]

  """
  def list_failover_clusters(repo \\ Repo) do
    repo.all(FailoverCluster)
  end

  @doc """
  Gets a single failover_cluster.

  Raises `Ecto.NoResultsError` if the Failover cluster does not exist.

  ## Examples

      iex> get_failover_cluster!(123)
      %FailoverCluster{}

      iex> get_failover_cluster!(456)
      ** (Ecto.NoResultsError)

  """
  def get_failover_cluster!(id, repo \\ Repo), do: repo.get!(FailoverCluster, id)

  @doc """
  Creates a failover_cluster.

  ## Examples

      iex> create_failover_cluster(%{field: value})
      {:ok, %FailoverCluster{}}

      iex> create_failover_cluster(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_failover_cluster(attrs \\ %{}, repo \\ Repo) do
    %FailoverCluster{}
    |> FailoverCluster.changeset(attrs)
    |> repo.insert()
    |> broadcast(:insert)
  end

  @doc """
  Updates a failover_cluster.

  ## Examples

      iex> update_failover_cluster(failover_cluster, %{field: new_value})
      {:ok, %FailoverCluster{}}

      iex> update_failover_cluster(failover_cluster, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_failover_cluster(%FailoverCluster{} = failover_cluster, attrs, repo \\ Repo) do
    failover_cluster
    |> FailoverCluster.changeset(attrs)
    |> repo.update()
    |> broadcast(:update)
  end

  @doc """
  Deletes a failover_cluster.

  ## Examples

      iex> delete_failover_cluster(failover_cluster)
      {:ok, %FailoverCluster{}}

      iex> delete_failover_cluster(failover_cluster)
      {:error, %Ecto.Changeset{}}

  """
  def delete_failover_cluster(%FailoverCluster{} = failover_cluster, repo \\ Repo) do
    failover_cluster
    |> repo.delete()
    |> broadcast(:delete)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking failover_cluster changes.

  ## Examples

      iex> change_failover_cluster(failover_cluster)
      %Ecto.Changeset{data: %FailoverCluster{}}

  """
  def change_failover_cluster(%FailoverCluster{} = failover_cluster, attrs \\ %{}) do
    FailoverCluster.changeset(failover_cluster, attrs)
  end

  def find_or_create(attrs, transaction_repo \\ Repo) do
    Multi.new()
    |> Multi.run(:selected, fn repo, _ ->
      {:ok,
       repo.one(
         from(failover_cluster in FailoverCluster,
           where:
             failover_cluster.type == ^attrs.type and
               failover_cluster.name == ^attrs.name
         )
       )}
    end)
    |> Multi.run(:created, fn repo, %{selected: sel} ->
      maybe_insert(sel, repo, attrs)
    end)
    |> transaction_repo.transaction()
  end

  defp maybe_insert(nil = _selected, repo, attrs) do
    %FailoverCluster{}
    |> FailoverCluster.changeset(attrs)
    |> repo.insert()
    |> broadcast(:insert)
  end

  defp maybe_insert(%FailoverCluster{} = _selected, _repo, _attrs) do
    {:ok, nil}
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:redis_cluster, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end
