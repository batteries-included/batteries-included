defmodule KubeServices.KubeState do
  use Supervisor

  alias KubeServices.ConnectionPool
  alias K8s.Resource
  alias CommonCore.ApiVersionKind
  alias KubeServices.KubeState.Runner

  @default_table :default_state_table

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    should_watch = Keyword.get(opts, :should_watch, true)
    Supervisor.init(children(should_watch), strategy: :one_for_one)
  end

  defp children(true) do
    [{KubeServices.KubeState.Runner, name: default_state_table()}] ++
      Enum.map(CommonCore.ApiVersionKind.all_known(), &spec/1)
  end

  defp children(false) do
    [{KubeServices.KubeState.Runner, name: default_state_table()}]
  end

  def spec(type) do
    type_name = type |> Atom.to_string() |> Macro.camelize()
    id = "KubeServices.KubeState.ResourceWatcher.#{type_name}"

    Supervisor.child_spec(
      {KubeServices.KubeState.ResourceWatcher,
       [
         connection_func: &ConnectionPool.get/0,
         client: K8s.Client,
         resource_type: type,
         table_name: default_state_table()
       ]},
      id: id
    )
  end

  def default_state_table, do: @default_table

  @spec snapshot(atom | :ets.tid()) :: map()
  def snapshot(t \\ @default_table) do
    Runner.snapshot(t)
  end

  @spec get!(atom() | :ets.tid(), map()) :: map()
  def get!(t \\ @default_table, resource) do
    get!(
      t,
      ApiVersionKind.resource_type(resource),
      Resource.namespace(resource),
      Resource.name(resource)
    )
  end

  @spec get!(atom() | :ets.tid(), atom(), binary(), binary()) :: map()
  def get!(t \\ @default_table, resource_type, namespace, name) do
    case get(t, resource_type, namespace, name) do
      {:ok, %{} = res} ->
        res

      :missing ->
        raise KubeServices.KubeState.NoResultsError,
          name: name,
          namespace: namespace,
          resource_type: resource_type
    end
  end

  @spec get(atom() | :ets.tid(), map()) :: :missing | {:ok, map()}
  def get(t \\ @default_table, resource),
    do:
      get(
        t,
        ApiVersionKind.resource_type(resource),
        Resource.namespace(resource),
        Resource.name(resource)
      )

  @spec get(atom() | :ets.tid(), atom(), binary(), binary()) :: :missing | {:ok, map()}
  def get(t \\ @default_table, resource_type, namespace, name) do
    Runner.get(t, resource_type, namespace, name)
  end

  @spec get_all(atom() | :ets.tid(), atom()) :: list(map)
  def get_all(t \\ @default_table, res_type) do
    t
    |> Runner.get_all(res_type)
    |> Enum.sort_by(&KubeResources.ResourceVersion.sortable_resource_version/1)
  end

  @spec get_owned_resources(atom() | :ets.tid(), atom(), list(String.t())) :: list(map)
  def get_owned_resources(t \\ @default_table, resource_type, owner_uids) do
    Enum.filter(get_all(t, resource_type), fn rsrc ->
      Enum.any?(get_in(rsrc, ~w|metadata ownerReferences|) || [], fn oref ->
        Enum.member?(owner_uids, Map.get(oref, "uid"))
      end)
    end)
  end

  def get_events(t \\ @default_table, involved_uid) do
    t
    |> Runner.get_all(:event)
    |> Enum.filter(fn e -> get_in(e, ~w(involvedObject uid)) == involved_uid end)
    |> Enum.sort_by(&KubeResources.ResourceVersion.sortable_resource_version/1)
  end
end
