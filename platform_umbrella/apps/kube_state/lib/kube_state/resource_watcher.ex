defmodule KubeState.ResourceWatcher do
  @behaviour Bella.Watcher

  alias KubeState.Runner
  alias KubeState.ApiVersionKind
  alias Bella.Watcher.State

  require Logger

  @client K8s.Client

  def add(resource, %State{} = watcher_state) do
    state_table = state_table(watcher_state)
    resource_type = resource_type(watcher_state)
    clean_resource = clean(resource, watcher_state)

    Logger.debug("Add event for #{resource_type}",
      resource: clean_resource,
      state_table: state_table
    )

    Runner.add(state_table, resource_type, clean_resource)
  end

  def delete(resource, %State{} = watcher_state) do
    state_table = state_table(watcher_state)
    resource_type = resource_type(watcher_state)
    clean_resource = clean(resource, watcher_state)
    Logger.debug("Delete event for #{resource_type} removing from #{state_table}")
    Runner.delete(state_table, resource_type, clean_resource)
  end

  def modify(resource, %State{} = watcher_state) do
    state_table = state_table(watcher_state)
    resource_type = resource_type(watcher_state)
    clean_resource = clean(resource, watcher_state)

    Runner.update(state_table, resource_type, clean_resource)
  end

  defp clean(resource, %State{} = watcher_state) do
    {api_version, kind} = watcher_state |> resource_type() |> ApiVersionKind.from_resource_type()

    resource
    |> Map.put_new("apiVersion", api_version)
    |> Map.put_new("kind", kind)
    |> update_in(["metadata"], fn m -> Map.drop(m || %{}, ["managedFields"]) end)
    |> Map.drop(["data"])
  end

  def operation(%State{} = watcher_state) do
    {api_version, kind} = watcher_state |> resource_type() |> ApiVersionKind.from_resource_type()
    @client.list(api_version, kind)
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
