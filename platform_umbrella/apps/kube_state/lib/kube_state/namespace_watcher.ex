defmodule KubeState.NamespaceWatcher do
  @behaviour Bella.Watcher

  require Logger

  def add(map) do
    :ok
  end

  def delete(map) do
    :ok
  end

  def modify(map) do
    :ok
  end

  def operation do
    K8s.Client.list("v1", "Namespace")
  end
end
