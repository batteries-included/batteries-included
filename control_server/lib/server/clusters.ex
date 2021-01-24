defmodule Server.Clusters do
  @moduledoc """
  The Clusters context.
  """

  import Ecto.Query, warn: false
  alias Server.Repo

  alias Server.Clusters.KubeCluster

  @doc """
  Returns the list of kube_clusters.

  ## Examples

      iex> list_kube_clusters()
      [%KubeCluster{}, ...]

  """
  def list_kube_clusters do
    Repo.all(KubeCluster)
  end

  @doc """
  Gets a single kube_cluster.

  Raises `Ecto.NoResultsError` if the Kube cluster does not exist.

  ## Examples

      iex> get_kube_cluster!(123)
      %KubeCluster{}

      iex> get_kube_cluster!(456)
      ** (Ecto.NoResultsError)

  """
  def get_kube_cluster!(id), do: Repo.get!(KubeCluster, id)

  @doc """
  Creates a kube_cluster.

  ## Examples

      iex> create_kube_cluster(%{field: value})
      {:ok, %KubeCluster{}}

      iex> create_kube_cluster(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_kube_cluster(attrs \\ %{}, allowed \\ [:adopted, :external_uid]) do
    %KubeCluster{}
    |> KubeCluster.changeset(attrs, allowed)
    |> Repo.insert()
    |> broadcast_change([:kube_cluster, :created])
  end

  @doc """
  Updates a kube_cluster.

  ## Examples

      iex> update_kube_cluster(kube_cluster, %{field: new_value})
      {:ok, %KubeCluster{}}

      iex> update_kube_cluster(kube_cluster, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_kube_cluster(
        %KubeCluster{} = kube_cluster,
        attrs,
        allowed \\ [:adopted, :external_uid]
      ) do
    kube_cluster
    |> KubeCluster.changeset(attrs, allowed)
    |> Repo.update()
    |> broadcast_change([:kube_cluster, :updated])
  end

  @doc """
  Deletes a kube_cluster.

  ## Examples

      iex> delete_kube_cluster(kube_cluster)
      {:ok, %KubeCluster{}}

      iex> delete_kube_cluster(kube_cluster)
      {:error, %Ecto.Changeset{}}

  """
  def delete_kube_cluster(%KubeCluster{} = kube_cluster) do
    Repo.delete(kube_cluster)
    |> broadcast_change([:kube_cluster, :deleted])
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking kube_cluster changes.

  ## Examples

      iex> change_kube_cluster(kube_cluster)
      %Ecto.Changeset{data: %KubeCluster{}}

  """
  def change_kube_cluster(
        %KubeCluster{} = kube_cluster,
        attrs \\ %{},
        allowed \\ [:adopted, :external_uid]
      ) do
    KubeCluster.changeset(kube_cluster, attrs, allowed)
  end

  @topic inspect(__MODULE__)

  def subscribe do
    Phoenix.PubSub.subscribe(Server.PubSub, @topic)
  end

  defp broadcast_change({:ok, result}, event) do
    Phoenix.PubSub.broadcast(Server.PubSub, @topic, {__MODULE__, event, result})
    {:ok, result}
  end

  defp broadcast_change(change, event) do
    change
  end
end
