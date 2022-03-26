defmodule ControlServer.Redis do
  @moduledoc """
  The Redis context.
  """

  import Ecto.Query, warn: false
  alias ControlServer.Repo

  alias ControlServer.Redis.FailoverCluster

  @doc """
  Returns the list of failover_clusters.

  ## Examples

      iex> list_failover_clusters()
      [%FailoverCluster{}, ...]

  """
  def list_failover_clusters do
    Repo.all(FailoverCluster)
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
  def get_failover_cluster!(id), do: Repo.get!(FailoverCluster, id)

  @doc """
  Creates a failover_cluster.

  ## Examples

      iex> create_failover_cluster(%{field: value})
      {:ok, %FailoverCluster{}}

      iex> create_failover_cluster(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_failover_cluster(attrs \\ %{}) do
    %FailoverCluster{}
    |> FailoverCluster.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a failover_cluster.

  ## Examples

      iex> update_failover_cluster(failover_cluster, %{field: new_value})
      {:ok, %FailoverCluster{}}

      iex> update_failover_cluster(failover_cluster, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_failover_cluster(%FailoverCluster{} = failover_cluster, attrs) do
    failover_cluster
    |> FailoverCluster.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a failover_cluster.

  ## Examples

      iex> delete_failover_cluster(failover_cluster)
      {:ok, %FailoverCluster{}}

      iex> delete_failover_cluster(failover_cluster)
      {:error, %Ecto.Changeset{}}

  """
  def delete_failover_cluster(%FailoverCluster{} = failover_cluster) do
    Repo.delete(failover_cluster)
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
end
