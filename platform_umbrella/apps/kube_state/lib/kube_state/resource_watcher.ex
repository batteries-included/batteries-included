defmodule KubeState.ResourceWatcher do
  @behaviour Bella.Watcher

  alias KubeState.Runner
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
    {api_version, kind} = watcher_state |> resource_type() |> api_kind_version()

    resource
    |> Map.put_new("apiVersion", api_version)
    |> Map.put_new("kind", kind)
    |> update_in(["metadata"], fn m -> Map.drop(m || %{}, ["managedFields"]) end)
    |> Map.drop(["data"])
  end

  def operation(%State{} = watcher_state) do
    {api_version, kind} = watcher_state |> resource_type() |> api_kind_version()
    @client.list(api_version, kind)
  end

  defp api_kind_version(:namespaces), do: {"v1", "Namespace"}
  defp api_kind_version(:pods), do: {"v1", "Pod"}
  defp api_kind_version(:services), do: {"v1", "Service"}
  defp api_kind_version(:service_accounts), do: {"v1", "ServiceAccount"}
  defp api_kind_version(:nodes), do: {"v1", "Node"}
  defp api_kind_version(:config_maps), do: {"v1", "ConfigMap"}
  defp api_kind_version(:deployments), do: {"apps/v1", "Deployment"}
  defp api_kind_version(:stateful_sets), do: {"apps/v1", "StatefulSet"}
  defp api_kind_version(:roles), do: {"rbac.authorization.k8s.io/v1", "Role"}
  defp api_kind_version(:role_bindings), do: {"rbac.authorization.k8s.io/v1", "RoleBinding"}
  defp api_kind_version(:cluster_roles), do: {"rbac.authorization.k8s.io/v1", "ClusterRole"}

  defp api_kind_version(:cluster_role_bindings),
    do: {"rbac.authorization.k8s.io/v1", "ClusterRoleBinding"}

  defp api_kind_version(:crds), do: {"apiextensions.k8s.io/v1", "CustomResourceDefinition"}

  defp api_kind_version(:istio_gateways), do: {"networking.istio.io/v1alpha3", "Gateway"}

  defp api_kind_version(:istio_virtual_services),
    do: {"networking.istio.io/v1alpha3", "VirtualService"}

  defp api_kind_version(:service_monitors), do: {"monitoring.coreos.com/v1", "ServiceMonitor"}
  defp api_kind_version(:pod_monitors), do: {"monitoring.coreos.com/v1", "PodMonitor"}
  defp api_kind_version(:prometheus), do: {"monitoring.coreos.com/v1", "Prometheus"}

  defp api_kind_version(:knative_servings),
    do: {"operator.knative.dev/v1alpha1", "KnativeServing"}

  defp api_kind_version(:knative_services), do: {"serving.knative.dev/v1", "Service"}

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
