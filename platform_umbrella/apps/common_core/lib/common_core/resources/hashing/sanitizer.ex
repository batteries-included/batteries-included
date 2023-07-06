defmodule CommonCore.Resources.Hashing.Sanitizer do
  @bad_meta_keys ~w(resourceVersion generation creationTimestamp uid managedFields)
  @bad_annotation_keys ["battery/hash"]
  @bad_top_keys ["status"]

  def sanitize(obj) do
    obj
    |> Map.drop(@bad_top_keys)
    |> clean_meta()
    |> clean_annotations()
  end

  defp clean_meta(%{"metadata" => _meta} = obj) do
    update_in(obj, ~w|metadata|, fn val -> Map.drop(val, @bad_meta_keys) end)
  end

  defp clean_meta(obj), do: obj

  defp clean_annotations(%{"metadata" => %{"annotations" => _ann}} = obj) do
    update_in(obj, ~w|metadata annotations|, fn val -> Map.drop(val, @bad_annotation_keys) end)
  end

  defp clean_annotations(obj), do: obj
end
