defmodule KubeServices.Timeline.Kube do
  use Supervisor

  @watched_types [:namspace, :pod, :node, :deployment, :stateful_set]

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  defp children() do
    Enum.map(@watched_types, &spec/1)
  end

  defp spec(type) do
    type_name = type |> Atom.to_string() |> Macro.camelize()
    id = "KubeServices.Timeline.KubeWatcher.#{type_name}"

    Supervisor.child_spec(
      {KubeServices.Timeline.KubeWatcher, [resource_type: type]},
      id: id
    )
  end
end
