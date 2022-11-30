defmodule HomeBase.ControlServerClusters do
  @moduledoc """
  The ControlServerClusters context.
  """

  import Ecto.Query, warn: false
  alias HomeBase.Repo

  alias HomeBase.ControlServerClusters.Installation

  @doc """
  Returns the list of installations.

  ## Examples

      iex> list_installations()
      [%Installation{}, ...]

  """
  def list_installations do
    Repo.all(Installation)
  end

  @doc """
  Gets a single installation.

  Raises `Ecto.NoResultsError` if the Installation does not exist.

  ## Examples

      iex> get_installation!(123)
      %Installation{}

      iex> get_installation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_installation!(id), do: Repo.get!(Installation, id)

  @doc """
  Creates a installation.

  ## Examples

      iex> create_installation(%{field: value})
      {:ok, %Installation{}}

      iex> create_installation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_installation(attrs \\ %{}) do
    %Installation{}
    |> Installation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a installation.

  ## Examples

      iex> update_installation(installation, %{field: new_value})
      {:ok, %Installation{}}

      iex> update_installation(installation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_installation(%Installation{} = installation, attrs) do
    installation
    |> Installation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a installation.

  ## Examples

      iex> delete_installation(installation)
      {:ok, %Installation{}}

      iex> delete_installation(installation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_installation(%Installation{} = installation) do
    Repo.delete(installation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking installation changes.

  ## Examples

      iex> change_installation(installation)
      %Ecto.Changeset{data: %Installation{}}

  """
  def change_installation(%Installation{} = installation, attrs \\ %{}) do
    Installation.changeset(installation, attrs)
  end
end
