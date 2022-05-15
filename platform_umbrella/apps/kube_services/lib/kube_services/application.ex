defmodule KubeServices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias KubeExt.ConnectionPool
  alias KubeState.ResourceWatcher

  @resource_watchers [
    {:namespaces, ResourceWatcher.Namespaces},
    {:pods, ResourceWatcher.Pods},
    {:services, ResourceWatcher.Services},
    {:service_accounts, ResourceWatcher.ServiceAccounts},
    {:nodes, ResourceWatcher.Nodes},
    {:config_maps, ResourceWatcher.ConfigMaps},
    {:deployments, ResourceWatcher.Deployments},
    {:stateful_sets, ResourceWatcher.StatefulSets},
    {:roles, ResourceWatcher.Roles},
    {:role_bindings, ResourceWatcher.RoleBindings},
    {:cluster_roles, ResourceWatcher.ClusterRoles},
    {:cluster_role_bindings, ResourceWatcher.ClusterRoleBindings},
    {:istio_gateways, ResourceWatcher.IstioGateways},
    {:istio_virtual_services, ResourceWatcher.IstioVirtualServices},
    {:service_monitors, ResourceWatcher.ServiceMonitors},
    {:pod_monitors, ResourceWatcher.PodMonitors},
    {:prometheus, ResourceWatcher.Prometheus},
    {:knative_servings, ResourceWatcher.KnativeServings},
    {:knative_services, ResourceWatcher.KnativeServices}
  ]

  @impl true
  def start(_type, _args) do
    children = children(start_services?())

    opts = [strategy: :one_for_one, name: KubeServices.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp start_services?, do: Application.get_env(:kube_services, :start_services)

  def children(true = _run) do
    [
      {Registry, [keys: :unique, name: KubeServices.Registry.Worker]},
      KubeServices.Usage.Poller,
      KubeServices.BaseServicesSupervisor,
      KubeServices.BaseServicesHydrator
    ] ++ Enum.map(@resource_watchers, &resource_worker_child_spec/1)
  end

  def children(_run), do: []

  defp resource_worker_child_spec({resource_type, id} = _tuple) do
    Supervisor.child_spec(
      {Bella.Watcher.Worker,
       [
         watcher: ResourceWatcher,
         connection_func: &ConnectionPool.get/0,
         retry_watch: true,
         extra: %{
           resource_type: resource_type,
           table_name: KubeState.default_state_table()
         }
       ]},
      id: id
    )
  end
end
