defmodule KubeState.Runner do
  use GenServer

  import K8s.Resource
  import EventCenter.KubeState

  alias EventCenter.KubeState.Payload

  def start_link(opts) do
    table_name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, table_name, opts)
  end

  @impl true
  def init(table_name) do
    ets_table = :ets.new(table_name, [:bag, :named_table, read_concurrency: true])
    {:ok, {ets_table}}
  end

  def get(table_name, resource_type) do
    case :ets.lookup(table_name, resource_type) do
      [] ->
        :missing

      resource_tuples ->
        {:ok, Enum.map(resource_tuples, fn {^resource_type, resource} -> resource end)}
    end
  end

  def add(table_name, resource_type, resource) do
    GenServer.call(table_name, {:add, resource_type, resource})
  end

  def delete(table_name, resource_type, resource) do
    GenServer.call(table_name, {:delete, resource_type, resource})
  end

  def update(table_name, resource_type, resource) do
    GenServer.call(table_name, {:update, resource_type, resource})
  end

  @impl true
  def handle_call({:add, resource_type, resource}, _from, {ets_table}) do
    :ets.insert(ets_table, {resource_type, resource})

    result_list = :ets.lookup(ets_table, resource_type)

    broadcast(resource_type, %Payload{
      resource: resource,
      new_resource_list: result_list,
      action: :add
    })

    {:reply, :ok, {ets_table}}
  end

  def handle_call({:delete, resource_type, resource}, _from, {ets_table}) do
    case get(ets_table, resource_type) do
      {:ok, existing_resources} ->
        kept =
          existing_resources
          |> Enum.reject(fn r -> is_same(r, resource) end)
          |> Enum.map(fn r -> {resource_type, r} end)
          |> Enum.to_list()

        :ets.delete(ets_table, resource_type)
        :ets.insert(ets_table, kept)

        broadcast(resource_type, %Payload{
          resource: resource,
          new_resource_list: kept,
          action: :delete
        })
    end

    {:reply, :ok, {ets_table}}
  end

  def handle_call({:update, resource_type, resource}, _from, {ets_table}) do
    case get(ets_table, resource_type) do
      {:ok, existing_resources} ->
        kept =
          existing_resources
          |> Enum.reject(fn r -> is_same(r, resource) end)
          |> Enum.map(fn r -> {resource_type, r} end)
          |> Enum.to_list()

        result_list = [{resource_type, resource} | kept]

        :ets.delete(ets_table, resource_type)
        :ets.insert(ets_table, result_list)

        broadcast(resource_type, %Payload{
          resource: resource,
          new_resource_list: result_list,
          action: :update
        })
    end

    {:reply, :ok, {ets_table}}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp is_same(r_one, r_two) do
    api_version(r_one) == api_version(r_two) &&
      kind(r_one) == kind(r_two) &&
      namespace(r_one) == namespace(r_two) &&
      name(r_one) == name(r_two)
  end
end
