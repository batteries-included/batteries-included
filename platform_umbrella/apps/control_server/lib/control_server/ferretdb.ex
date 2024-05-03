defmodule ControlServer.FerretDB do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.FerretDB.FerretService
  alias EventCenter.Database, as: DatabaseEventCenter

  @doc """
  Returns the list of ferret_services.

  ## Examples

      iex> list_ferret_services()
      [%FerretService{}, ...]

  """
  def list_ferret_services do
    Repo.all(FerretService)
  end

  @doc """
  Gets a single ferret_service.

  Raises `Ecto.NoResultsError` if the Ferret service does not exist.

  ## Examples

      iex> get_ferret_service!(123)
      %FerretService{}

      iex> get_ferret_service!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ferret_service!(id), do: Repo.get!(FerretService, id)

  @doc """
  Creates a ferret_service.

  ## Examples

      iex> create_ferret_service(%{field: value})
      {:ok, %FerretService{}}

      iex> create_ferret_service(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ferret_service(attrs \\ %{}) do
    %FerretService{}
    |> FerretService.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:insert)
  end

  @doc """
  Updates a ferret_service.

  ## Examples

      iex> update_ferret_service(ferret_service, %{field: new_value})
      {:ok, %FerretService{}}

      iex> update_ferret_service(ferret_service, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ferret_service(%FerretService{} = ferret_service, attrs) do
    ferret_service
    |> FerretService.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @doc """
  Deletes a ferret_service.

  ## Examples

      iex> delete_ferret_service(ferret_service)
      {:ok, %FerretService{}}

      iex> delete_ferret_service(ferret_service)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ferret_service(%FerretService{} = ferret_service) do
    ferret_service
    |> Repo.delete()
    |> broadcast(:delete)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ferret_service changes.

  ## Examples

      iex> change_ferret_service(ferret_service)
      %Ecto.Changeset{data: %FerretService{}}

  """
  def change_ferret_service(%FerretService{} = ferret_service, attrs \\ %{}) do
    FerretService.changeset(ferret_service, attrs)
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:ferret_service, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end
