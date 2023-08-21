defmodule KubeServices.Timeline.Kube do
  @moduledoc false
  use Supervisor

  require Logger

  @watched_types [:namspace, :pod, :node, :deployment, :stateful_set]
  @pod_status_table :pod_status

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    Supervisor.init(children(), strategy: :one_for_one)
  end

  defp children do
    Enum.map(@watched_types, &spec/1) ++
      [
        {KubeServices.Timeline.PodStatus, [table_name: @pod_status_table]}
      ]
  end

  defp spec(type) do
    type_name = type |> Atom.to_string() |> Macro.camelize()
    id = "KubeServices.Timeline.KubeWatcher.#{type_name}"

    Supervisor.child_spec(
      {KubeServices.Timeline.KubeWatcher, [resource_type: type]},
      id: id
    )
  end

  def pod_status_table, do: @pod_status_table
end
