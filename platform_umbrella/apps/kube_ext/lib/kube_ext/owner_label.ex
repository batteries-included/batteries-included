defmodule KubeExt.OwnerLabel do
  import K8s.Resource.FieldAccessors

  def get_owner(resource) do
    resource |> labels() |> Map.get("battery/owner", nil)
  end
end
