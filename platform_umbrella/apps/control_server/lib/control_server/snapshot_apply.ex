defmodule ControlServer.SnapshotApply do
  @moduledoc """
  The SnapshotApply context.
  """

  import Ecto.Query, warn: false

  alias ControlServer.Repo
  alias ControlServer.SnapshotApply.UmbrellaSnapshot

  @doc """
  Returns the list of umbrella_snapshots.

  ## Examples

      iex> list_umbrella_snapshots()
      [%UmbrellaSnapshot{}, ...]

  """
  def list_umbrella_snapshots do
    Repo.all(UmbrellaSnapshot)
  end

  @doc """
  Gets a single umbrella_snapshot.

  Raises `Ecto.NoResultsError` if the Umbrella snapshot does not exist.

  ## Examples

      iex> get_umbrella_snapshot!(123)
      %UmbrellaSnapshot{}

      iex> get_umbrella_snapshot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_umbrella_snapshot!(id), do: Repo.get!(UmbrellaSnapshot, id)

  @doc """
  Creates a umbrella_snapshot.

  ## Examples

      iex> create_umbrella_snapshot(%{field: value})
      {:ok, %UmbrellaSnapshot{}}

      iex> create_umbrella_snapshot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_umbrella_snapshot(attrs \\ %{}) do
    %UmbrellaSnapshot{}
    |> UmbrellaSnapshot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a umbrella_snapshot.

  ## Examples

      iex> update_umbrella_snapshot(umbrella_snapshot, %{field: new_value})
      {:ok, %UmbrellaSnapshot{}}

      iex> update_umbrella_snapshot(umbrella_snapshot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_umbrella_snapshot(%UmbrellaSnapshot{} = umbrella_snapshot, attrs) do
    umbrella_snapshot
    |> UmbrellaSnapshot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a umbrella_snapshot.

  ## Examples

      iex> delete_umbrella_snapshot(umbrella_snapshot)
      {:ok, %UmbrellaSnapshot{}}

      iex> delete_umbrella_snapshot(umbrella_snapshot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_umbrella_snapshot(%UmbrellaSnapshot{} = umbrella_snapshot) do
    Repo.delete(umbrella_snapshot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking umbrella_snapshot changes.

  ## Examples

      iex> change_umbrella_snapshot(umbrella_snapshot)
      %Ecto.Changeset{data: %UmbrellaSnapshot{}}

  """
  def change_umbrella_snapshot(%UmbrellaSnapshot{} = umbrella_snapshot, attrs \\ %{}) do
    UmbrellaSnapshot.changeset(umbrella_snapshot, attrs)
  end

  @doc """
  Delete `UmbrellaSnapshot` older than the specified number
  of hours. The number of deleted records is returned.
  """
  @spec reap_old_snapshots(number) :: pos_integer()
  def reap_old_snapshots(hours_to_keep \\ 72) do
    end_time = DateTime.add(DateTime.utc_now(), -hours_to_keep, :hour)
    query = from s in UmbrellaSnapshot, where: s.inserted_at < ^end_time
    {deleted_count, _} = Repo.delete_all(query)
    deleted_count
  end
end
