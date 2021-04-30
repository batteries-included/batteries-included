defmodule ControlServer.Services do
  @moduledoc """
  The Services context.
  """

  import Ecto.Query, warn: false
  alias ControlServer.Repo

  alias ControlServer.Services.BaseService

  @doc """
  Returns the list of base_services.

  ## Examples

      iex> list_base_services()
      [%BaseService{}, ...]

  """
  def list_base_services do
    Repo.all(BaseService)
  end

  @doc """
  Gets a single base_service.

  Raises `Ecto.NoResultsError` if the Base service does not exist.

  ## Examples

      iex> get_base_service!(123)
      %BaseService{}

      iex> get_base_service!(456)
      ** (Ecto.NoResultsError)

  """
  def get_base_service!(id), do: Repo.get!(BaseService, id)

  @doc """
  Creates a base_service.

  ## Examples

      iex> create_base_service(%{field: value})
      {:ok, %BaseService{}}

      iex> create_base_service(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_base_service(attrs \\ %{}) do
    %BaseService{}
    |> BaseService.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a base_service.

  ## Examples

      iex> update_base_service(base_service, %{field: new_value})
      {:ok, %BaseService{}}

      iex> update_base_service(base_service, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_base_service(%BaseService{} = base_service, attrs) do
    base_service
    |> BaseService.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a base_service.

  ## Examples

      iex> delete_base_service(base_service)
      {:ok, %BaseService{}}

      iex> delete_base_service(base_service)
      {:error, %Ecto.Changeset{}}

  """
  def delete_base_service(%BaseService{} = base_service) do
    Repo.delete(base_service)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking base_service changes.

  ## Examples

      iex> change_base_service(base_service)
      %Ecto.Changeset{data: %BaseService{}}

  """
  def change_base_service(%BaseService{} = base_service, attrs \\ %{}) do
    BaseService.changeset(base_service, attrs)
  end
end
