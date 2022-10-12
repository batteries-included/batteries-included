defmodule KubeExt.Hashing.Sanitizer do
  @bad_meta_keys ["annotations", "resourceVersion", "generation", "creationTimestamp", "uid"]
  @bad_top_keys ["status"]

  def sanitize(%{"metadata" => meta} = obj) do
    clean_meta = Map.drop(meta, @bad_meta_keys)

    obj
    |> Map.drop(@bad_top_keys)
    |> Map.put("metadata", clean_meta)
  end

  def sanitize(%{} = obj), do: Map.drop(obj, @bad_top_keys)
end
