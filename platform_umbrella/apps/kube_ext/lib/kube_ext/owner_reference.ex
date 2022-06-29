defmodule KubeExt.OwnerRefernce do
  @spec get_owner(map()) :: binary() | nil
  def get_owner(resource) do
    resource
    |> get_in(~w(metadata ownerReferences))
    |> extract_first_owner_uid()
  end

  defp extract_first_owner_uid([owner | _rest]) do
    Map.get(owner, "uid", nil)
  end

  defp extract_first_owner_uid(_), do: nil
end
