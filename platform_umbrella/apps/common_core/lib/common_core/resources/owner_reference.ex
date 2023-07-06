defmodule CommonCore.Resources.OwnerReference do
  @spec get_owner(map()) :: binary() | nil
  def get_owner(resource) do
    resource
    |> get_all_owners()
    |> List.first(nil)
  end

  def get_all_owners(resource) do
    resource
    |> get_in([
      Access.key("metadata", %{}),
      Access.key("ownerReferences", [])
    ])
    |> Enum.map(&Map.get(&1, "uid", nil))
    |> Enum.reject(&(&1 == nil))
  end
end
