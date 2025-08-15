defmodule CommonCore.Resources.CopyDown do
  @moduledoc false
  import K8s.Resource.FieldAccessors

  @banned_labels ["battery/managed.direct"]
  @banned_annotations ["battery/hash"]

  @default_labels %{
    "battery/managed" => "true",
    "app.kubernetes.io/managed-by" => "batteries-included",
    "battery/managed.indirect" => "true"
  }

  def indirect_labels, do: @default_labels

  def copy_labels_downward(resource) do
    good_labels =
      resource
      |> labels()
      |> Enum.filter(fn {key, _} -> key not in @banned_labels end)
      |> Map.new()
      |> Map.merge(@default_labels)

    if has_template_meta(resource) do
      merge(resource, ~w|spec template metadata labels|, good_labels)
    else
      resource
    end
  end

  def copy_annotations_downward(resource) do
    good_annotations =
      resource
      |> annotations()
      |> Enum.filter(fn {key, _} -> key not in @banned_annotations end)
      |> Map.new()

    if has_template_meta(resource) do
      merge(resource, ~w|spec template metadata annotations|, good_annotations)
    else
      resource
    end
  end

  defp has_template_meta(resource) do
    get_in(resource, ~w(spec template metadata)) != nil
  end

  defp merge(resource, path, good_map) do
    # make it so that we never error out while updating
    access_path = Enum.map(path, fn p -> Access.key(p, %{}) end)

    # Merge the good labels with the others
    update_in(resource, access_path, fn existing ->
      Map.merge(good_map, existing || %{})
    end)
  end
end
