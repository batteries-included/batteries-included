defmodule ControlServer.Redis do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.Redis.RedisInstance
  alias EventCenter.Database, as: DatabaseEventCenter

  @doc """
  Returns the list of redis_instances.

  ## Examples

      iex> list_redis_instances()
      [%RedisInstance{}, ...]

  """
  def list_redis_instances do
    Repo.all(RedisInstance)
  end

  def list_redis_instances(params) do
    Repo.Flop.validate_and_run(RedisInstance, params, for: RedisInstance)
  end

  @doc """
  Gets a single redis_instance.

  Raises `Ecto.NoResultsError` if the Redis instance does not exist.

  ## Examples

      iex> get_redis_instance!(123)
      %RedisInstance{}

      iex> get_redis_instance!(456)
      ** (Ecto.NoResultsError)

  """
  def get_redis_instance!(id, opts \\ []) do
    RedisInstance
    |> preload(^Keyword.get(opts, :preload, []))
    |> Repo.get!(id)
  end

  @doc """
  Creates a redis_instance.

  ## Examples

      iex> create_redis_instance(%{field: value})
      {:ok, %RedisInstance{}}

      iex> create_redis_instance(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_redis_instance(attrs \\ %{}) do
    %RedisInstance{}
    |> RedisInstance.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:insert)
  end

  @doc """
  Updates a redis_instance.

  ## Examples

      iex> update_redis_instance(redis_instance, %{field: new_value})
      {:ok, %RedisInstance{}}

      iex> update_redis_instance(redis_instance, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_redis_instance(%RedisInstance{} = redis_instance, attrs) do
    redis_instance
    |> RedisInstance.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @doc """
  Deletes a redis_instance.

  ## Examples

      iex> delete_redis_instance(redis_instance)
      {:ok, %RedisInstance{}}

      iex> delete_redis_instance(redis_instance)
      {:error, %Ecto.Changeset{}}

  """
  def delete_redis_instance(%RedisInstance{} = redis_instance) do
    redis_instance
    |> Repo.delete()
    |> broadcast(:delete)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking redis_instance changes.

  ## Examples

      iex> change_redis_instance(redis_instance)
      %Ecto.Changeset{data: %RedisInstance{}}

  """
  def change_redis_instance(%RedisInstance{} = redis_instance, attrs \\ %{}) do
    RedisInstance.changeset(redis_instance, attrs)
  end

  def find_or_create(attrs, transaction_repo \\ Repo) do
    Multi.new()
    |> Multi.run(:selected, fn repo, _ ->
      {:ok,
       repo.one(
         from(redis_instance in RedisInstance,
           where:
             redis_instance.type == ^attrs.type and
               redis_instance.name == ^attrs.name
         )
       )}
    end)
    |> Multi.run(:created, fn repo, %{selected: sel} ->
      maybe_insert(sel, repo, attrs)
    end)
    |> transaction_repo.transaction()
  end

  defp maybe_insert(nil = _selected, repo, attrs) do
    %RedisInstance{}
    |> RedisInstance.changeset(attrs)
    |> repo.insert()
    |> broadcast(:insert)
  end

  defp maybe_insert(%RedisInstance{} = _selected, _repo, _attrs) do
    {:ok, nil}
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:redis_cluster, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end
