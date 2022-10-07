defmodule ControlServer.Postgres do
  @moduledoc """
  The Postgres context.
  """

  import Ecto.Query, warn: false

  alias ControlServer.Postgres.Cluster
  alias ControlServer.Repo
  alias EventCenter.Database, as: DatabaseEventCenter

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
    |> broadcast(:insert)
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
    |> broadcast(:update)
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
    cluster |> Repo.delete() |> broadcast(:delete)
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

  def find_or_create(attrs, transaction_repo \\ Repo) do
    Multi.new()
    |> Multi.run(:selected, fn repo, _ ->
      {:ok,
       repo.one(
         from(cluster in Cluster,
           where:
             cluster.type == ^attrs.type and
               cluster.team_name == ^attrs.team_name and
               cluster.name == ^attrs.name
         )
       )}
    end)
    |> Multi.run(:created, fn repo, %{selected: sel} ->
      maybe_insert(sel, repo, attrs)
    end)
    |> transaction_repo.transaction()
  end

  defp maybe_insert(nil = _selected, repo, attrs) do
    %Cluster{}
    |> Cluster.changeset(attrs)
    |> repo.insert()
    |> broadcast(:insert)
  end

  defp maybe_insert(%Cluster{} = _selected, _repo, _attrs) do
    {:ok, nil}
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:postgres_cluster, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end
