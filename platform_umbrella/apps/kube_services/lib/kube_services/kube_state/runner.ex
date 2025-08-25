defmodule KubeServices.KubeState.Runner do
  @moduledoc """
  Responsible for mediating state storage.
  """
  use GenServer

  import EventCenter.KubeState
  import K8s.Resource

  alias CommonCore.ApiVersionKind
  alias EventCenter.KubeState.Payload
  alias KubeServices.KubeState.Status

  def start_link(opts) do
    table_name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table_name, opts)
  end

  @impl GenServer
  def init(table_name) do
    ets_table = :ets.new(table_name, [:set, :named_table, read_concurrency: true])
    {:ok, {ets_table}}
  end

  @doc """
  Get the stored state of a resource.
  """
  @spec get(:ets.table(), atom(), String.t() | nil, String.t()) :: {:ok, map()} | :missing
  def get(table_name, resource_type, namespace, name) do
    case :ets.lookup(table_name, {resource_type, namespace, name}) do
      [{_key, resource}] -> {:ok, resource}
      _ -> :missing
    end
  end

  @doc """
  Get the stored state of all resources of type.
  """
  @spec get_all(:ets.table(), atom()) :: list()
  def get_all(table_name, resource_type) do
    table_name
    |> :ets.match({{resource_type, :_, :_}, :"$1"})
    |> Enum.map(fn [resource] -> resource end)
  end

  @doc """
  Get the stored state of all resources.
  """
  @spec snapshot(:ets.table()) :: map()
  def snapshot(table_name) do
    table_name
    |> :ets.tab2list()
    |> Enum.reduce(%{}, fn {{resource_type, _, _}, resource}, snap ->
      update_in(snap, [resource_type], fn l -> [resource | l || []] end)
    end)
    |> Map.drop(~w(event)a)
  end

  @doc """
  Add a resource.
  """
  @spec add(:ets.table(), map(), list()) :: term()
  def add(table_name, resource, opts \\ []) do
    GenServer.call(table_name, {:add, resource, opts})
  end

  @doc """
  Delete a resource.
  """
  @spec delete(:ets.table(), map(), list()) :: term()
  def delete(table_name, resource, opts \\ []) do
    GenServer.call(table_name, {:delete, resource, opts})
  end

  @doc """
  Update a resource.
  """
  @spec update(:ets.table(), map(), list()) :: term()
  def update(table_name, resource, opts \\ []) do
    GenServer.call(table_name, {:update, resource, opts})
  end

  @impl GenServer
  def handle_call({:add, resource, opts}, _from, {ets_table}) do
    :ets.insert(ets_table, {key(resource), resource})

    broadcast(:add, resource, opts, ets_table)
    {:reply, :ok, {ets_table}}
  end

  def handle_call({:delete, resource, opts}, _from, {ets_table}) do
    :ets.delete(ets_table, key(resource))

    broadcast(:delete, resource, opts, ets_table)
    {:reply, :ok, {ets_table}}
  end

  def handle_call({:update, resource, opts}, _from, {ets_table}) do
    :ets.insert(ets_table, {key(resource), resource})

    broadcast(:update, resource, opts, ets_table)
    {:reply, :ok, {ets_table}}
  end

  @impl GenServer
  def handle_info(_, state) do
    {:noreply, state}
  end

  @doc """
  Generate the key from the given resource.
  """
  def key(resource) do
    {ApiVersionKind.resource_type(resource), namespace(resource), name(resource)}
  end

  defp broadcast(action, resource, opts, table_name) do
    skip_broadcast = Keyword.get(opts, :skip_broadcast, false)
    Status.update(table_name)

    do_broadcast(skip_broadcast, action, resource)
  end

  defp do_broadcast(true = _skip, _action, _resource), do: nil

  defp do_broadcast(false = _skip, action, resource) do
    broadcast!(
      ApiVersionKind.resource_type(resource),
      %Payload{
        resource: resource,
        action: action
      }
    )
  end
end
