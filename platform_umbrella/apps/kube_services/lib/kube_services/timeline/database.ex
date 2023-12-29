defmodule KubeServices.Timeline.Database do
  @moduledoc false
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  defp children do
    Enum.map(CommonCore.Timeline.NamedDatabase.possible_schema_types(), &spec/1)
  end

  defp spec(type) do
    type_name = type |> Atom.to_string() |> Macro.camelize()
    id = "KubeServices.Timeline.DatabaseWatcher.#{type_name}"

    Supervisor.child_spec(
      {KubeServices.Timeline.DatabaseWatcher, [source_type: type]},
      id: id
    )
  end
end
