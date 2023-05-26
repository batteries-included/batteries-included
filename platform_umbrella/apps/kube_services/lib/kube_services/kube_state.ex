defmodule KubeServices.KubeState do
  use Supervisor

  alias KubeExt.ConnectionPool
  alias KubeExt.KubeState

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  defp children() do
    Enum.map(CommonCore.ApiVersionKind.all_known(), &spec/1)
  end

  def spec(type) do
    type_name = type |> Atom.to_string() |> Macro.camelize()
    id = "KubeExt.KubeState.ResourceWatcher.#{type_name}"

    Supervisor.child_spec(
      {KubeExt.KubeState.ResourceWatcher,
       [
         connection_func: &ConnectionPool.get/0,
         client: K8s.Client,
         resource_type: type,
         table_name: KubeState.default_state_table()
       ]},
      id: id
    )
  end
end
