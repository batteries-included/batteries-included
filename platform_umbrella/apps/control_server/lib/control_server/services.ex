defmodule ControlServer.Services do
  @moduledoc """
  The Services context.
  """

  import Ecto.Query, warn: false
  alias ControlServer.Repo
  alias Ecto.Multi

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
    Multi.new()
    |> Multi.insert(:base_service, change_base_service(%BaseService{}, attrs))
    |> Multi.run(:event_center, fn _repo, %{base_service: base_service} ->
      {broadcast(:insert, base_service), nil}
    end)
    |> Repo.transaction()
    |> unwrap_event()
  end

  def create_base_service!(attrs \\ %{}) do
    case create_base_service(attrs) do
      {:ok, base_service} -> base_service
      {:error, error} -> raise error
    end
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
    Multi.new()
    |> Multi.update(:base_service, change_base_service(base_service, attrs))
    |> Multi.run(:event_center, fn _repo, %{base_service: up_bs} ->
      {broadcast(:update, up_bs), nil}
    end)
    |> Repo.transaction()
    |> unwrap_event()
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
    Multi.new()
    |> Multi.delete(:base_service, base_service)
    |> Multi.run(:event_center, fn _repo, %{base_service: del_bs} ->
      {broadcast(:delete, del_bs), nil}
    end)
    |> Repo.transaction()
    |> unwrap_event()
  end

  defp broadcast(event, base_service) do
    EventCenter.BaseService.broadcast(event, base_service)
  end

  defp unwrap_event({:ok, %{base_service: base_service}}) do
    {:ok, base_service}
  end

  defp unwrap_event({:error, :base_service, changeset, _}) do
    {:error, changeset}
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

  def active?(path) do
    true ==
      Repo.one(
        from(bs in BaseService,
          where: bs.root_path == ^path,
          select: bs.is_active
        )
      )
  end
end
