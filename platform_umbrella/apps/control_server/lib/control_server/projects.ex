defmodule ControlServer.Projects do
  @moduledoc """
  The Projects context.
  """

  import Ecto.Query, warn: false
  alias ControlServer.Repo

  alias ControlServer.Projects.SystemProject

  @doc """
  Returns the list of system_projects.

  ## Examples

      iex> list_system_projects()
      [%SystemProject{}, ...]

  """
  def list_system_projects do
    Repo.all(SystemProject)
  end

  @doc """
  Gets a single system_project.

  Raises `Ecto.NoResultsError` if the System project does not exist.

  ## Examples

      iex> get_system_project!(123)
      %SystemProject{}

      iex> get_system_project!(456)
      ** (Ecto.NoResultsError)

  """
  def get_system_project!(id), do: Repo.get!(SystemProject, id)

  @doc """
  Creates a system_project.

  ## Examples

      iex> create_system_project(%{field: value})
      {:ok, %SystemProject{}}

      iex> create_system_project(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_system_project(attrs \\ %{}) do
    %SystemProject{}
    |> SystemProject.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a system_project.

  ## Examples

      iex> update_system_project(system_project, %{field: new_value})
      {:ok, %SystemProject{}}

      iex> update_system_project(system_project, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_system_project(%SystemProject{} = system_project, attrs) do
    system_project
    |> SystemProject.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a system_project.

  ## Examples

      iex> delete_system_project(system_project)
      {:ok, %SystemProject{}}

      iex> delete_system_project(system_project)
      {:error, %Ecto.Changeset{}}

  """
  def delete_system_project(%SystemProject{} = system_project) do
    Repo.delete(system_project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking system_project changes.

  ## Examples

      iex> change_system_project(system_project)
      %Ecto.Changeset{data: %SystemProject{}}

  """
  def change_system_project(%SystemProject{} = system_project, attrs \\ %{}) do
    SystemProject.changeset(system_project, attrs)
  end
end
