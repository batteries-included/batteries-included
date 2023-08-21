defmodule CommonCore.Resources.OwnerLabel do
  @moduledoc false
  import K8s.Resource.FieldAccessors

  @spec get_owner(map()) :: binary() | nil
  def get_owner(resource) do
    resource |> labels() |> Map.get("battery/owner", nil)
  end
end
