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
  alias EventCenter.Database, as: DatabaseEventCenter

  require Logger

  @doc """
  Returns the list of base_services.

  ## Examples

      iex> all()
      [%BaseService{}, ...]

  """
  def all(repo \\ Repo) do
    base_query()
    |> select_limited()
    |> repo.all()
  end

  def all_including_config(repo \\ Repo) do
    repo.all(base_query())
  end

  def from_service_types(service_types) do
    base_query()
    |> with_service_type_in(service_types)
    |> select_limited()
    |> Repo.all()
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
  def create_base_service(attrs \\ %{}, repo \\ Repo) do
    %BaseService{}
    |> BaseService.changeset(attrs)
    |> repo.insert()
    |> broadcast(:insert)
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
    attrs
    |> find_or_create_multi()
    |> Repo.transaction()
    |> unwrap_transaction_return()
  end

  def find_or_create_multi(attrs) do
    Multi.new()
    |> Multi.run(:selected, fn repo, _ ->
      {:ok, repo.one(from(bs in BaseService, where: bs.root_path == ^attrs.root_path))}
    end)
    |> Multi.run(:created, fn repo, %{selected: sel} ->
      maybe_insert(sel, repo, attrs)
    end)
  end

  def maybe_insert(nil = _selected, repo, attrs) do
    %BaseService{}
    |> BaseService.changeset(attrs)
    |> repo.insert()
    |> broadcast(:insert)
  end

  def maybe_insert(%BaseService{} = _selected, _repo, _attrs) do
    {:ok, nil}
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
    |> broadcast(:update)
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
    base_service
    |> Repo.delete()
    |> broadcast(:delete)
  end

  defp broadcast({:ok, cluster} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:base_service, action, cluster)
    result
  end

  defp broadcast(result, _action), do: result

  defp unwrap_transaction_return({:ok, %{base_service: base_service}}) do
    {:ok, base_service}
  end

  defp unwrap_transaction_return({:error, :base_service, changeset, _}) do
    {:error, changeset}
  end

  def active?(path) do
    Repo.exists?(from(bs in BaseService, where: bs.root_path == ^path))
  end

  def activate_defaults do
    services = ServiceConfigs.default_services()
    IO.puts("Services = #{inspect(services)}")

    Enum.each(services, fn service ->
      IO.puts("Activating default service #{inspect(service)}")
      RunnableService.activate!(service)
    end)
  end

  def base_query do
    from(bs in BaseService)
  end

  def with_service_type_in(query \\ BaseService, service_types) do
    where(query, [bs], bs.service_type in ^service_types)
  end

  def select_limited(query \\ BaseService) do
    select(query, [:id, :root_path, :service_type, :updated_at, :inserted_at])
  end
end
