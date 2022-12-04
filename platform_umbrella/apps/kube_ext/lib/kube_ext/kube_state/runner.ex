defmodule KubeExt.KubeState.Runner do
  use GenServer

  import K8s.Resource
  import EventCenter.KubeState

  alias EventCenter.KubeState.Payload
  alias KubeExt.ApiVersionKind

  def start_link(opts) do
    table_name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table_name, opts)
  end

  @impl GenServer
  def init(table_name) do
    ets_table = :ets.new(table_name, [:set, :named_table, read_concurrency: true])
    {:ok, {ets_table}}
  end

  @spec get(atom() | :ets.tid(), atom(), String.t(), String.t()) :: {:ok, map()} | :missing
  def get(table_name, resource_type, namespace, name) do
    case :ets.lookup(table_name, {resource_type, namespace, name}) do
      [{_key, resource}] -> {:ok, resource}
      _ -> :missing
    end
  end

  @spec get_all(atom() | :ets.tid(), atom()) :: list()
  def get_all(table_name, resource_type) do
    table_name
    |> :ets.match({{resource_type, :_, :_}, :"$1"})
    |> Enum.map(fn [resource] -> resource end)
  end

  @spec snapshot(atom() | :ets.tid()) :: map()
  def snapshot(table_name) do
    table_name
    |> :ets.tab2list()
    |> Enum.reduce(%{}, fn {{resource_type, _, _}, resource}, snap ->
      update_in(snap, [resource_type], fn l -> [resource | l || []] end)
    end)
  end

  def add(table_name, resource) do
    GenServer.call(table_name, {:add, resource})
  end

  def delete(table_name, resource) do
    GenServer.call(table_name, {:delete, resource})
  end

  def update(table_name, resource) do
    GenServer.call(table_name, {:update, resource})
  end

  @impl GenServer
  def handle_call({:add, resource}, _from, {ets_table}) do
    :ets.insert_new(ets_table, {key(resource), resource})

    with :ok <- do_broadcast(:add, resource) do
      {:reply, :ok, {ets_table}}
    end

    {:reply, :ok, {ets_table}}
  end

  def handle_call({:delete, resource}, _from, {ets_table}) do
    :ets.delete(ets_table, key(resource))

    with :ok <- do_broadcast(:delete, resource) do
      {:reply, :ok, {ets_table}}
    end

    {:reply, :ok, {ets_table}}
  end

  def handle_call({:update, resource}, _from, {ets_table}) do
    :ets.insert(ets_table, {key(resource), resource})

    with :ok <- do_broadcast(:update, resource) do
      {:reply, :ok, {ets_table}}
    end
  end

  @impl GenServer
  def handle_info(_, state) do
    {:noreply, state}
  end

  def key(resource) do
    {ApiVersionKind.resource_type(resource), namespace(resource), name(resource)}
  end

  defp do_broadcast(action, resource) do
    broadcast(
      ApiVersionKind.resource_type(resource),
      %Payload{
        resource: resource,
        action: action
      }
    )
  end
end
