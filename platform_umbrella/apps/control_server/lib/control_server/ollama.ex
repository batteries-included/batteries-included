defmodule ControlServer.Ollama do
  @moduledoc """
  The Ollama context.
  """

  use ControlServer, :context

  alias CommonCore.Ollama.ModelInstance
  alias EventCenter.Database, as: DatabaseEventCenter

  @spec list_model_instances() :: list(ModelInstance.t())
  @doc """
  Returns the list of model_instances.

  ## Examples

      iex> list_model_instances()
      [%ModelInstance{}, ...]

  """
  def list_model_instances do
    Repo.all(ModelInstance)
  end

  def list_model_instances(params) do
    Repo.Flop.validate_and_run(ModelInstance, params, for: ModelInstance)
  end

  @doc """
  Gets a single model_instance.

  Raises `Ecto.NoResultsError` if the Model instance does not exist.

  ## Examples

      iex> get_model_instance!(123)
      %ModelInstance{}

      iex> get_model_instance!(456)
      ** (Ecto.NoResultsError)

  """
  def get_model_instance!(id, opts \\ []) do
    ModelInstance
    |> preload(^Keyword.get(opts, :preload, []))
    |> Repo.get!(id)
  end

  @doc """
  Creates a model_instance.

  ## Examples

      iex> create_model_instance(%{field: value})
      {:ok, %ModelInstance{}}

      iex> create_model_instance(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_model_instance(attrs \\ %{}) do
    %ModelInstance{}
    |> ModelInstance.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:insert)
  end

  @doc """
  Updates a model_instance.

  ## Examples

      iex> update_model_instance(model_instance, %{field: new_value})
      {:ok, %ModelInstance{}}

      iex> update_model_instance(model_instance, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_model_instance(%ModelInstance{} = model_instance, attrs) do
    model_instance
    |> ModelInstance.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @doc """
  Deletes a model_instance.

  ## Examples

      iex> delete_model_instance(model_instance)
      {:ok, %ModelInstance{}}

      iex> delete_model_instance(model_instance)
      {:error, %Ecto.Changeset{}}

  """
  def delete_model_instance(%ModelInstance{} = model_instance) do
    model_instance
    |> Repo.delete()
    |> broadcast(:delete)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking model_instance changes.

  ## Examples

      iex> change_model_instance(model_instance)
      %Ecto.Changeset{data: %ModelInstance{}}

  """
  def change_model_instance(%ModelInstance{} = model_instance, attrs \\ %{}) do
    ModelInstance.changeset(model_instance, attrs)
  end

  defp broadcast({:ok, fc} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:model_instance, action, fc)
    result
  end

  defp broadcast(result, _action), do: result
end
