defmodule KubeExt.KubeState do
  @moduledoc """
  Documentation for `KubeState`.
  """

  alias K8s.Resource
  alias KubeExt.ApiVersionKind
  alias KubeExt.KubeState.Runner

  @default_table :default_state_table

  @spec default_state_table :: :default_state_table
  def default_state_table, do: @default_table

  @spec namespaces(atom | :ets.tid()) :: list()
  def namespaces(t \\ @default_table), do: get_all(t, :namespace, [])

  @spec pods(atom | :ets.tid()) :: list()
  def pods(t \\ @default_table), do: get_all(t, :pod, [])

  @spec services(atom | :ets.tid()) :: list()
  def services(t \\ @default_table), do: get_all(t, :service, [])

  @spec service_accounts(atom | :ets.tid()) :: list()
  def service_accounts(t \\ @default_table), do: get_all(t, :service_account, [])

  @spec deployments(atom | :ets.tid()) :: list()
  def deployments(t \\ @default_table), do: get_all(t, :deployment, [])

  @spec stateful_sets(atom | :ets.tid()) :: list()
  def stateful_sets(t \\ @default_table), do: get_all(t, :stateful_set, [])

  @spec nodes(atom | :ets.tid()) :: list()
  def nodes(t \\ @default_table), do: get_all(t, :node, [])

  @spec config_maps(atom | :ets.tid()) :: list()
  def config_maps(t \\ @default_table), do: get_all(t, :config_map, [])

  @spec roles(atom | :ets.tid()) :: list()
  def roles(t \\ @default_table), do: get_all(t, :role, [])

  @spec role_bindings(atom | :ets.tid()) :: list()
  def role_bindings(t \\ @default_table), do: get_all(t, :role_binding, [])

  @spec cluster_roles(atom | :ets.tid()) :: list()
  def cluster_roles(t \\ @default_table), do: get_all(t, :cluster_role, [])

  @spec cluster_role_bindings(atom | :ets.tid()) :: list()
  def cluster_role_bindings(t \\ @default_table), do: get_all(t, :cluster_role_binding, [])

  @spec istio_gateways(atom | :ets.tid()) :: list
  def istio_gateways(t \\ @default_table), do: get_all(t, :istio_gateway, [])

  @spec istio_virtual_services(atom | :ets.tid()) :: list()
  def istio_virtual_services(t \\ @default_table), do: get_all(t, :istio_virtual_service, [])

  @spec service_monitors(atom | :ets.tid()) :: list()
  def service_monitors(t \\ @default_table), do: get_all(t, :service_monitor, [])

  @spec pod_monitors(atom | :ets.tid()) :: list()
  def pod_monitors(t \\ @default_table), do: get_all(t, :pod_monitor, [])

  @spec prometheus(atom | :ets.tid()) :: list()
  def prometheus(t \\ @default_table), do: get_all(t, :prometheus, [])

  @spec knative_servings(atom | :ets.tid()) :: list()
  def knative_servings(t \\ @default_table), do: get_all(t, :knative_serving, [])

  @spec knative_services(atom | :ets.tid()) :: list
  def knative_services(t \\ @default_table), do: get_all(t, :knative_service, [])

  @spec knative_configurations(atom | :ets.tid()) :: list
  def knative_configurations(t \\ @default_table), do: get_all(t, :knative_configuration, [])

  @spec knative_revisions(atom | :ets.tid()) :: list
  def knative_revisions(t \\ @default_table), do: get_all(t, :knative_revision, [])

  @spec postgresqls(atom | :ets.tid()) :: list
  def postgresqls(t \\ @default_table), do: get_all(t, :postgresql, [])

  @spec redis_failovers(atom | :ets.tid()) :: list
  def redis_failovers(t \\ @default_table), do: get_all(t, :redis_failover, [])

  @spec table_to_list(atom | :ets.tid()) :: list
  def table_to_list(t \\ @default_table), do: :ets.tab2list(t)

  def get_resource(t \\ @default_table, resource) do
    resource_type = ApiVersionKind.resource_type(resource)
    name = Resource.name(resource)
    namespace = Resource.namespace(resource)

    t
    |> get_all(resource_type, [])
    |> Enum.find(nil, fn pos ->
      Resource.name(pos) == name && Resource.namespace(pos) == namespace
    end)
  end

  @spec get_all(atom() | :ets.tid(), atom()) :: list()
  def get_all(table, res_type) do
    with {:ok, result} <- Runner.get(table, res_type) do
      result
    end
  end

  def get_all(table, res_type, default) do
    case Runner.get(table, res_type) do
      {:ok, result} ->
        result

      _ ->
        default
    end
  end
end
