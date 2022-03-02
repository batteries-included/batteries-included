defmodule KubeState.NamespaceWatcher do
  @behaviour Bella.Watcher

  require Logger

  def add(_map) do
    :ok
  end

  def delete(_map) do
    :ok
  end

  def modify(_map) do
    :ok
  end

  def operation do
    K8s.Client.list("v1", "Namespace")
  end
end
