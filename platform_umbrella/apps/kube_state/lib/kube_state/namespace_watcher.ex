defmodule KubeState.NamespaceWatcher do
  @behaviour Bella.Watcher

  require Logger

  def add(_map, _state) do
    :ok
  end

  def delete(_map, _state) do
    :ok
  end

  def modify(_map, _state) do
    :ok
  end

  def operation(_state) do
    K8s.Client.list("v1", "Namespace")
  end
end
