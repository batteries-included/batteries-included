defmodule ControlServer.TraditionalServices do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.TraditionalServices.Service
  alias EventCenter.Database, as: DatabaseEventCenter

  @doc """
  Returns the list of traditional_services.

  ## Examples

      iex> list_traditional_services()
      [%Service{}, ...]

  """
  def list_traditional_services do
    Repo.all(Service)
  end

  @doc """
  Gets a single service.

  Raises `Ecto.NoResultsError` if the Service does not exist.

  ## Examples

      iex> get_service!(123)
      %Service{}

      iex> get_service!(456)
      ** (Ecto.NoResultsError)

  """
  def get_service!(id, opts \\ []) do
    Service
    |> preload(^Keyword.get(opts, :preload, []))
    |> Repo.get!(id)
  end

  @doc """
  Creates a service.

  ## Examples

      iex> create_service(%{field: value})
      {:ok, %Service{}}

      iex> create_service(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_service(attrs \\ %{}) do
    %Service{}
    |> Service.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:insert)
  end

  @doc """
  Updates a service.

  ## Examples

      iex> update_service(service, %{field: new_value})
      {:ok, %Service{}}

      iex> update_service(service, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_service(%Service{} = service, attrs) do
    service
    |> Service.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @doc """
  Deletes a service.

  ## Examples

      iex> delete_service(service)
      {:ok, %Service{}}

      iex> delete_service(service)
      {:error, %Ecto.Changeset{}}

  """
  def delete_service(%Service{} = service) do
    service
    |> Repo.delete()
    |> broadcast(:delete)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking service changes.

  ## Examples

      iex> change_service(service)
      %Ecto.Changeset{data: %Service{}}

  """
  def change_service(%Service{} = service, attrs \\ %{}) do
    Service.changeset(service, attrs)
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:backend_service, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end
