defmodule KubeServices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias KubeExt.ConnectionPool
  alias KubeState.ResourceWatcher

  @impl true
  def start(_type, _args) do
    children = children(start_services?())

    opts = [strategy: :one_for_one, name: KubeServices.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_services?, do: Application.get_env(:kube_services, :start_services)

  def children(true = _run) do
    [
      Supervisor.child_spec(
        {Bella.Watcher.Worker,
         [
           watcher: ResourceWatcher,
           connection_func: &ConnectionPool.get/0,
           extra: %{resource_type: :namespaces, table_name: KubeState.default_state_table()}
         ]},
        id: ResourceWatcher.Namespaces
      ),
      Supervisor.child_spec(
        {Bella.Watcher.Worker,
         [
           watcher: ResourceWatcher,
           connection_func: &ConnectionPool.get/0,
           extra: %{resource_type: :pods, table_name: KubeState.default_state_table()}
         ]},
        id: ResourceWatcher.Pods
      ),
      Supervisor.child_spec(
        {Bella.Watcher.Worker,
         [
           watcher: ResourceWatcher,
           connection_func: &ConnectionPool.get/0,
           extra: %{resource_type: :services, table_name: KubeState.default_state_table()}
         ]},
        id: ResourceWatcher.Services
      ),
      Supervisor.child_spec(
        {Bella.Watcher.Worker,
         [
           watcher: ResourceWatcher,
           connection_func: &ConnectionPool.get/0,
           extra: %{resource_type: :deployments, table_name: KubeState.default_state_table()}
         ]},
        id: ResourceWatcher.Deployments
      ),
      Supervisor.child_spec(
        {Bella.Watcher.Worker,
         [
           watcher: ResourceWatcher,
           connection_func: &ConnectionPool.get/0,
           extra: %{resource_type: :stateful_sets, table_name: KubeState.default_state_table()}
         ]},
        id: ResourceWatcher.StatefulSets
      ),
      Supervisor.child_spec(
        {Bella.Watcher.Worker,
         [
           watcher: ResourceWatcher,
           connection_func: &ConnectionPool.get/0,
           extra: %{resource_type: :nodes, table_name: KubeState.default_state_table()}
         ]},
        id: ResourceWatcher.Nodes
      ),
      {Registry, [keys: :unique, name: KubeServices.Registry.Worker]},
      KubeServices.Usage.Poller,
      KubeServices.BaseServicesSupervisor,
      KubeServices.BaseServicesHydrator
    ]
  end

  def children(_run), do: []
end
