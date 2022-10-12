defmodule KubeExt.Watcher do
  @callback operation(KubeExt.Watcher.State.t()) :: K8s.Operation.t()

  @callback add(map(), KubeExt.Watcher.State.t()) :: :ok | :error
  @callback modify(map(), KubeExt.Watcher.State.t()) :: :ok | :error
  @callback delete(map(), KubeExt.Watcher.State.t()) :: :ok | :error
end
