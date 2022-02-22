defmodule ControlServer.Services do
  @moduledoc """
  The Services context.
  """

  import Ecto.Query, warn: false

  alias ControlServer.Repo
  alias ControlServer.ServiceConfigs
  alias ControlServer.Services.BaseService
  alias ControlServer.Services.RunnableService
  alias Ecto.Multi

  require Logger

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
    |> unwrap_transaction_return()
  end

  def create_base_service!(attrs \\ %{}) do
    case create_base_service(attrs) do
      {:ok, base_service} -> base_service
      {:error, error} -> raise error
    end
  end

  def find_or_create!(attrs) do
    case find_or_create(attrs) do
      {:ok, base_service} -> base_service
      {:error, error} -> raise error
    end
  end

  def find_or_create(attrs) do
    Multi.new()
    |> Multi.run(:selected, fn repo, _ ->
      {:ok, repo.one(from(bs in BaseService, where: bs.root_path == ^attrs.root_path))}
    end)
    |> Multi.run(:created, fn repo, %{selected: sel} ->
      maybe_insert(sel, repo, attrs)
    end)
    |> Multi.run(:base_service, &insert_event/2)
    |> Repo.transaction()
    |> unwrap_transaction_return()
  end

  def maybe_insert(nil = _selected, repo, attrs) do
    repo.insert(BaseService.changeset(%BaseService{}, attrs))
  end

  def maybe_insert(%BaseService{} = _selected, _repo, _attrs) do
    {:ok, nil}
  end

  def insert_event(_repo, %{selected: nil, created: created}) do
    Logger.debug("Inserted -> #{inspect(created)}")
    {broadcast(:insert, created), created}
  end

  def insert_event(_repo, %{selected: selected, created: nil}) do
    Logger.debug("Selected -> #{inspect(selected)}")
    {:ok, selected}
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
    |> unwrap_transaction_return()
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
    |> unwrap_transaction_return()
  end

  defp broadcast(event, base_service) do
    EventCenter.BaseService.broadcast(event, base_service)
  end

  defp unwrap_transaction_return({:ok, %{base_service: base_service}}) do
    {:ok, base_service}
  end

  defp unwrap_transaction_return({:error, :base_service, changeset, _}) do
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
    Repo.exists?(from(bs in BaseService, where: bs.root_path == ^path))
  end

  def activate_defaults do
    services = ServiceConfigs.default_services()

    Enum.each(services, fn service ->
      IO.puts("Activating default service #{IO.inspect(service)}")
      RunnableService.activate!(service)
    end)
  end
end
