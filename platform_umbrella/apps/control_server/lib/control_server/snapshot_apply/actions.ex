defmodule ControlServer.SnapshotApply.Actions do
  @moduledoc false

  use ControlServer, :context

  alias ControlServer.SnapshotApply.KeycloakAction

  @doc """
  Returns the list of keycloak_actions.

  ## Examples

      iex> list_keycloak_actions()
      [%KeycloakAction{}, ...]

  """
  def list_keycloak_actions do
    Repo.all(KeycloakAction)
  end

  @doc """
  Gets a single keycloak_action.

  Raises `Ecto.NoResultsError` if the Keycloak action does not exist.

  ## Examples

      iex> get_keycloak_action!(123)
      %KeycloakAction{}

      iex> get_keycloak_action!(456)
      ** (Ecto.NoResultsError)

  """
  def get_keycloak_action!(id), do: Repo.get!(KeycloakAction, id)

  @doc """
  Creates a keycloak_action.

  ## Examples

      iex> create_keycloak_action(%{field: value})
      {:ok, %KeycloakAction{}}

      iex> create_keycloak_action(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_keycloak_action(attrs \\ %{}) do
    %KeycloakAction{}
    |> KeycloakAction.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a keycloak_action.

  ## Examples

      iex> update_keycloak_action(keycloak_action, %{field: new_value})
      {:ok, %KeycloakAction{}}

      iex> update_keycloak_action(keycloak_action, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_keycloak_action(%KeycloakAction{} = keycloak_action, attrs) do
    keycloak_action
    |> KeycloakAction.changeset(attrs, action: :update)
    |> Repo.update()
  end

  @doc """
  Deletes a keycloak_action.

  ## Examples

      iex> delete_keycloak_action(keycloak_action)
      {:ok, %KeycloakAction{}}

      iex> delete_keycloak_action(keycloak_action)
      {:error, %Ecto.Changeset{}}

  """
  def delete_keycloak_action(%KeycloakAction{} = keycloak_action) do
    Repo.delete(keycloak_action)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking keycloak_action changes.

  ## Examples

      iex> change_keycloak_action(keycloak_action)
      %Ecto.Changeset{data: %KeycloakAction{}}

  """
  def change_keycloak_action(%KeycloakAction{} = keycloak_action, attrs \\ %{}) do
    KeycloakAction.changeset(keycloak_action, attrs)
  end
end
