defmodule ControlServer.Rook do
  @moduledoc """
  The Rook context.
  """

  import Ecto.Query, warn: false
  alias ControlServer.Repo

  alias CommonCore.Rook.CephCluster
  alias CommonCore.Rook.CephFilesystem

  @doc """
  Returns the list of ceph_cluster.

  ## Examples

      iex> list_ceph_cluster()
      [%CephCluster{}, ...]

  """
  def list_ceph_cluster do
    Repo.all(CephCluster)
  end

  @doc """
  Gets a single ceph_cluster.

  Raises `Ecto.NoResultsError` if the Ceph cluster does not exist.

  ## Examples

      iex> get_ceph_cluster!(123)
      %CephCluster{}

      iex> get_ceph_cluster!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ceph_cluster!(id), do: Repo.get!(CephCluster, id)

  @doc """
  Creates a ceph_cluster.

  ## Examples

      iex> create_ceph_cluster(%{field: value})
      {:ok, %CephCluster{}}

      iex> create_ceph_cluster(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ceph_cluster(attrs \\ %{}) do
    %CephCluster{}
    |> CephCluster.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ceph_cluster.

  ## Examples

      iex> update_ceph_cluster(ceph_cluster, %{field: new_value})
      {:ok, %CephCluster{}}

      iex> update_ceph_cluster(ceph_cluster, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ceph_cluster(%CephCluster{} = ceph_cluster, attrs) do
    ceph_cluster
    |> CephCluster.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ceph_cluster.

  ## Examples

      iex> delete_ceph_cluster(ceph_cluster)
      {:ok, %CephCluster{}}

      iex> delete_ceph_cluster(ceph_cluster)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ceph_cluster(%CephCluster{} = ceph_cluster) do
    Repo.delete(ceph_cluster)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ceph_cluster changes.

  ## Examples

      iex> change_ceph_cluster(ceph_cluster)
      %Ecto.Changeset{data: %CephCluster{}}

  """
  def change_ceph_cluster(%CephCluster{} = ceph_cluster, attrs \\ %{}) do
    CephCluster.changeset(ceph_cluster, attrs)
  end

  def list_ceph_filesystem do
    Repo.all(CephFilesystem)
  end

  def get_ceph_filesystem!(id), do: Repo.get!(CephFilesystem, id)

  def create_ceph_filesystem(attrs \\ %{}) do
    %CephFilesystem{}
    |> CephFilesystem.changeset(attrs)
    |> Repo.insert()
  end

  def update_ceph_filesystem(%CephFilesystem{} = ceph_filesystem, attrs) do
    ceph_filesystem
    |> CephFilesystem.changeset(attrs)
    |> Repo.update()
  end

  def delete_ceph_filesystem(%CephFilesystem{} = ceph_filesystem) do
    Repo.delete(ceph_filesystem)
  end

  def change_ceph_filesystem(%CephFilesystem{} = ceph_filesystem, attrs \\ %{}) do
    CephFilesystem.changeset(ceph_filesystem, attrs)
  end
end
