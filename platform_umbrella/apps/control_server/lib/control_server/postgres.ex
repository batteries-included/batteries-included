defmodule ControlServer.Postgres do
  @moduledoc """
  The Postgres context.
  """

  import Ecto.Query, warn: false

  alias ControlServer.Postgres.Cluster
  alias ControlServer.Repo

  alias Ecto.Multi

  require Logger

  @doc """
  Returns the list of clusters.

  ## Examples

      iex> list_clusters()
      [%Cluster{}, ...]

  """
  def list_clusters do
    Repo.all(Cluster)
  end

  def internal_clusters do
    Repo.all(from c in Cluster, where: c.type == :internal)
  end

  def normal_clusters do
    Repo.all(from c in Cluster, where: c.type != :internal)
  end

  @doc """
  Gets a single cluster.

  Raises `Ecto.NoResultsError` if the Cluster does not exist.

  ## Examples

      iex> get_cluster!(123)
      %Cluster{}

      iex> get_cluster!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cluster!(id), do: Repo.get!(Cluster, id)

  @doc """
  Creates a cluster.

  ## Examples

      iex> create_cluster(%{field: value})
      {:ok, %Cluster{}}

      iex> create_cluster(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cluster(attrs \\ %{}, repo \\ Repo) do
    %Cluster{}
    |> Cluster.changeset(attrs)
    |> repo.insert()
  end

  @doc """
  Updates a cluster.

  ## Examples

      iex> update_cluster(cluster, %{field: new_value})
      {:ok, %Cluster{}}

      iex> update_cluster(cluster, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cluster(%Cluster{} = cluster, attrs) do
    cluster
    |> Cluster.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cluster.

  ## Examples

      iex> delete_cluster(cluster)
      {:ok, %Cluster{}}

      iex> delete_cluster(cluster)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cluster(%Cluster{} = cluster) do
    Repo.delete(cluster)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cluster changes.

  ## Examples

      iex> change_cluster(cluster)
      %Ecto.Changeset{data: %Cluster{}}

  """
  def change_cluster(%Cluster{} = cluster, attrs \\ %{}) do
    Cluster.changeset(cluster, attrs)
  end

  def insert_default_clusters do
    Multi.new()
    |> Multi.run(:count_clusters, fn repo, %{} = _ ->
      {:ok, repo.aggregate(Cluster, :count)}
    end)
    |> Multi.run(:maybe_insert, &maybe_insert_default_clusters/2)
    |> Repo.transaction()
  end

  defp maybe_insert_default_clusters(repo, %{count_clusters: 0}) do
    create_cluster(KubeRawResources.Battery.control_cluster(), repo)
  end

  defp maybe_insert_default_clusters(_repo, %{count_clusters: cluster_count} = _data) do
    Logger.debug("Not inserting new postgres clusters there's already #{cluster_count}")
    {:ok, nil}
  end
end
