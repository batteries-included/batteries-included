defmodule KubeState.ResourceWatcher do
  @behaviour Bella.Watcher

  import KubeState.Runner
  alias Bella.Watcher.State

  require Logger

  @client K8s.Client

  def add(resource, %State{} = watcher_state) do
    state_table = state_table(watcher_state)
    resource_type = resource_type(watcher_state)
    Logger.debug("Add event for #{resource_type}", resource: resource, state_table: state_table)
    add(state_table, resource_type, resource)
  end

  def delete(resource, %State{} = watcher_state) do
    state_table = state_table(watcher_state)
    resource_type = resource_type(watcher_state)
    Logger.debug("Delete event for #{resource_type} removing from #{state_table}")
    delete(state_table, resource_type, resource)
  end

  def modify(resource, %State{} = watcher_state) do
    state_table = state_table(watcher_state)
    resource_type = resource_type(watcher_state)

    Logger.debug("Update event for #{resource_type}", resource: resource, state_table: state_table)

    update(state_table, resource_type, resource)
  end

  def operation(%State{} = watcher_state) do
    case resource_type(watcher_state) do
      :namespaces ->
        @client.list("v1", "Namespace")

      :pods ->
        @client.list("v1", "Pod")

      :services ->
        @client.list("v1", "Service")

      :deployments ->
        @client.list("apps/v1", "Deployment")

      :stateful_sets ->
        @client.list("apps/v1", "StatefulSets")
    end
  end

  defp state_table(watcher_state) do
    case watcher_state do
      %{extra: %{table_name: table_name}} ->
        table_name

      %{} ->
        :default_state_table
    end
  end

  defp resource_type(watcher_state) do
    case watcher_state do
      %{extra: %{resource_type: resource_type}} ->
        resource_type
    end
  end
end
