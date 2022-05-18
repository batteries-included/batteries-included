defmodule KubeState do
  @moduledoc """
  Documentation for `KubeState`.
  """

  alias K8s.Resource

  @default_table :default_state_table

  @spec default_state_table :: :default_state_table
  def default_state_table, do: @default_table

  @spec namespaces(atom | :ets.tid()) :: list
  def namespaces(t \\ @default_table), do: get_all(t, :namespaces, [])

  @spec pods(atom | :ets.tid()) :: list
  def pods(t \\ @default_table), do: get_all(t, :pods, [])

  @spec services(atom | :ets.tid()) :: list
  def services(t \\ @default_table), do: get_all(t, :services, [])

  @spec service_accounts(atom | :ets.tid()) :: list
  def service_accounts(t \\ @default_table), do: get_all(t, :service_accounts, [])

  @spec deployments(atom | :ets.tid()) :: list
  def deployments(t \\ @default_table), do: get_all(t, :deployments, [])

  @spec stateful_sets(atom | :ets.tid()) :: list
  def stateful_sets(t \\ @default_table), do: get_all(t, :stateful_sets, [])

  @spec nodes(atom | :ets.tid()) :: list
  def nodes(t \\ @default_table), do: get_all(t, :nodes, [])

  @spec config_maps(atom | :ets.tid()) :: list
  def config_maps(t \\ @default_table), do: get_all(t, :config_maps, [])

  @spec roles(atom | :ets.tid()) :: list
  def roles(t \\ @default_table), do: get_all(t, :roles, [])

  @spec role_bindings(atom | :ets.tid()) :: list
  def role_bindings(t \\ @default_table), do: get_all(t, :role_bindings, [])

  @spec cluster_roles(atom | :ets.tid()) :: list
  def cluster_roles(t \\ @default_table), do: get_all(t, :cluster_roles, [])

  @spec cluster_role_bindings(atom | :ets.tid()) :: list
  def cluster_role_bindings(t \\ @default_table), do: get_all(t, :cluster_role_bindings, [])

  @spec istio_gateways(atom | :ets.tid()) :: list
  def istio_gateways(t \\ @default_table), do: get_all(t, :istio_gateways, [])

  @spec istio_virtual_services(atom | :ets.tid()) :: list
  def istio_virtual_services(t \\ @default_table), do: get_all(t, :istio_virtual_services, [])

  @spec service_monitors(atom | :ets.tid()) :: list
  def service_monitors(t \\ @default_table), do: get_all(t, :service_monitors, [])

  @spec pod_monitors(atom | :ets.tid()) :: list
  def pod_monitors(t \\ @default_table), do: get_all(t, :pod_monitors, [])

  @spec prometheus(atom | :ets.tid()) :: list
  def prometheus(t \\ @default_table), do: get_all(t, :prometheus, [])

  @spec knative_servings(atom | :ets.tid()) :: list
  def knative_servings(t \\ @default_table), do: get_all(t, :knative_servings, [])

  @spec knative_services(atom | :ets.tid()) :: list
  def knative_services(t \\ @default_table), do: get_all(t, :knative_services, [])

  def get_resource(t \\ @default_table, resource) do
    resource_type = KubeState.ApiVersionKind.resource_type(resource)
    name = Resource.name(resource)
    namespace = Resource.namespace(resource)

    t
    |> get_all(resource_type, [])
    |> Enum.find(nil, fn pos ->
      Resource.name(pos) == name && Resource.namespace(pos) == namespace
    end)
  end

  def get_all(table, res_type) do
    case KubeState.Runner.get(table, res_type) do
      {:ok, result} ->
        result
    end
  end

  def get_all(table, res_type, default) do
    case KubeState.Runner.get(table, res_type) do
      {:ok, result} ->
        result

      _ ->
        default
    end
  end
end
