defmodule CommonCore.StateSummary.FromKubeState do
  @moduledoc false
  alias CommonCore.StateSummary

  @namespaceless [:namespace, :node, :cluster_role, :cluster_role_binding]

  def find_state_resource(%StateSummary{} = state, resource_type, name)
      when is_atom(resource_type) and resource_type in @namespaceless do
    state
    |> Map.get(:kube_state, %{})
    |> Map.get(resource_type, %{})
    |> Enum.find(nil, fn r ->
      name == get_in(r, ~w(metadata name))
    end)
  end

  def find_state_resource(%StateSummary{} = state, resource_type, namespace, name) do
    state
    |> Map.get(:kube_state, %{})
    |> Map.get(resource_type, %{})
    |> Enum.find(nil, fn resource ->
      namespace == get_in(resource, ~w(metadata namespace)) &&
        name == get_in(resource, ~w(metadata name))
    end)
  end
end
