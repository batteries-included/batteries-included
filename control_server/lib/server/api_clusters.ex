defmodule Server.ApiClusters do
  @moduledoc """
  The Clusters context for modifying data via rest api
  """

  import Ecto.Query, warn: false
  alias Server.Repo

  alias Server.Clusters.KubeCluster

  @doc """
  Creates a kube_cluster.

  ## Examples

      iex> create_kube_cluster(%{field: value})
      {:ok, %KubeCluster{}}

      iex> create_kube_cluster(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_kube_cluster(attrs \\ %{}) do
    %KubeCluster{}
    |> KubeCluster.api_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a kube_cluster.

  ## Examples

      iex> update_kube_cluster(kube_cluster, %{field: new_value})
      {:ok, %KubeCluster{}}

      iex> update_kube_cluster(kube_cluster, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_kube_cluster(%KubeCluster{} = kube_cluster, attrs) do
    kube_cluster
    |> KubeCluster.api_changeset(attrs)
    |> Repo.update()
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
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking kube_cluster changes.

  ## Examples

      iex> change_kube_cluster(kube_cluster)
      %Ecto.Changeset{data: %KubeCluster{}}

  """
  def change_kube_cluster(%KubeCluster{} = kube_cluster, attrs \\ %{}) do
    KubeCluster.api_changeset(kube_cluster, attrs)
  end
end
