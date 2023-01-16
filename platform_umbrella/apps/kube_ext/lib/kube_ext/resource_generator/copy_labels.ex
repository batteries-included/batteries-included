defmodule KubeExt.CopyLabels do
  import K8s.Resource.FieldAccessors

  @banned_labels ["battery/managed.direct"]
  @default_labels %{"battery/managed" => "true", "battery/managed.indirect" => "true"}

  def indirect_labels, do: @default_labels

  def copy_labels_downward(resource) do
    good_labels =
      resource
      |> labels()
      |> Enum.filter(fn {key, _} -> key not in @banned_labels end)
      |> Map.new()
      |> Map.merge(@default_labels)

    copy_labels_downward(resource, good_labels)
  end

  defp copy_labels_downward(
         %{"spec" => %{"template" => %{"metadata" => %{"labels" => _}}}} = resource,
         good_labels
       ) do
    merge_labels(resource, ~w|spec template metadata labels|, good_labels)
  end

  defp copy_labels_downward(resource, _good_labels), do: resource

  defp merge_labels(resource, path, good_labels) do
    # make it so that we never error out while updating
    access_path = Enum.map(path, fn p -> Access.key(p, %{}) end)

    # Merge the good labels with the others
    update_in(resource, access_path, fn existing ->
      Map.merge(good_labels, existing || %{})
    end)
  end
end
