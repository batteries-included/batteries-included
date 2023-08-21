defmodule ControlServer.SnapshotApply.Keycloak do
  @moduledoc """
  The KeycloakSnapshotApply context.
  """

  import Ecto.Query, warn: false

  alias ControlServer.Repo
  alias ControlServer.SnapshotApply.KeycloakSnapshot

  @doc """
  Returns the list of keycloak_snapshots.

  ## Examples

      iex> list_keycloak_snapshots()
      [%KeycloakSnapshot{}, ...]

  """
  def list_keycloak_snapshots do
    Repo.all(KeycloakSnapshot)
  end

  @doc """
  Gets a single keycloak_snapshot.

  Raises `Ecto.NoResultsError` if the Keycloak snapshot does not exist.

  ## Examples

      iex> get_keycloak_snapshot!(123)
      %KeycloakSnapshot{}

      iex> get_keycloak_snapshot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_keycloak_snapshot!(id), do: Repo.get!(KeycloakSnapshot, id)

  @doc """
  Creates a keycloak_snapshot.

  ## Examples

      iex> create_keycloak_snapshot(%{field: value})
      {:ok, %KeycloakSnapshot{}}

      iex> create_keycloak_snapshot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_keycloak_snapshot(attrs \\ %{}) do
    %KeycloakSnapshot{}
    |> KeycloakSnapshot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a keycloak_snapshot.

  ## Examples

      iex> update_keycloak_snapshot(keycloak_snapshot, %{field: new_value})
      {:ok, %KeycloakSnapshot{}}

      iex> update_keycloak_snapshot(keycloak_snapshot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_keycloak_snapshot(%KeycloakSnapshot{} = keycloak_snapshot, attrs) do
    keycloak_snapshot
    |> KeycloakSnapshot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a keycloak_snapshot.

  ## Examples

      iex> delete_keycloak_snapshot(keycloak_snapshot)
      {:ok, %KeycloakSnapshot{}}

      iex> delete_keycloak_snapshot(keycloak_snapshot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_keycloak_snapshot(%KeycloakSnapshot{} = keycloak_snapshot) do
    Repo.delete(keycloak_snapshot)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking keycloak_snapshot changes.

  ## Examples

      iex> change_keycloak_snapshot(keycloak_snapshot)
      %Ecto.Changeset{data: %KeycloakSnapshot{}}

  """
  def change_keycloak_snapshot(%KeycloakSnapshot{} = keycloak_snapshot, attrs \\ %{}) do
    KeycloakSnapshot.changeset(keycloak_snapshot, attrs)
  end
end
