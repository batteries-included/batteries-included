defmodule KubeServices.KubeState.Supervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.ApiVersionKind
  alias CommonCore.ConnectionPool
  alias KubeServices.KubeState.Runner

  @default_table :default_state_table

  def start_link(opts \\ []) do
    opts =
      opts
      |> Keyword.put_new(:should_watch, true)
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.put_new(:table_name, @default_table)

    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    Supervisor.init(children(opts), strategy: :one_for_one)
  end

  defp children(opts) do
    should_watch = Keyword.get(opts, :should_watch, true)
    table_name = Keyword.get(opts, :table_name, @default_table)

    to_watch = if should_watch, do: ApiVersionKind.all_known(), else: []

    [{Runner, name: table_name}] ++ Enum.map(to_watch, &spec(&1, opts))
  end

  def spec(type, opts) do
    type_name = type |> Atom.to_string() |> Macro.camelize()
    id = "KubeServices.KubeState.ResourceWatcher.#{type_name}"
    table_name = Keyword.get(opts, :table_name, @default_table)

    Supervisor.child_spec(
      {KubeServices.KubeState.ResourceWatcher,
       [
         connection_func: &ConnectionPool.get!/0,
         client: K8s.Client,
         resource_type: type,
         table_name: table_name
       ]},
      id: id
    )
  end
end
