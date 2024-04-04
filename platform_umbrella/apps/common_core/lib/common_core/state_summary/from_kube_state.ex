defmodule CommonCore.StateSummary.FromKubeState do
  @moduledoc false
  import CommonCore.Resources.FieldAccessors

  alias CommonCore.StateSummary

  @namespaceless ~w(
    certmanager_cluster_issuer
    cluster_role
    cluster_role_binding
    ingress_class_params
    namespace
    node
    storage_class
  )a

  def find_state_resource(%StateSummary{} = state, resource_type, name)
      when is_atom(resource_type) and resource_type in @namespaceless do
    state
    |> Map.get(:kube_state, %{})
    |> Map.get(resource_type, %{})
    |> Enum.find(nil, fn r -> name == name(r) end)
  end

  def find_state_resource(%StateSummary{} = state, resource_type, namespace, name) do
    state
    |> Map.get(:kube_state, %{})
    |> Map.get(resource_type, %{})
    |> Enum.find(nil, fn resource -> namespace == namespace(resource) && name == name(resource) end)
  end

  def all_resources(%StateSummary{} = state, type) do
    state
    |> Map.get(:kube_state, %{})
    |> Map.get(type, [])
  end
end
