defmodule KubeExt.Hashing do
  @hash_annotation_key "battery/hash"

  def get_hash(resource) do
    resource
    |> decorate_content_hash()
    |> get_in(["metadata", "annotations", @hash_annotation_key])
  end

  def decorate_content_hash(
        %{"metadata" => %{"annotations" => %{@hash_annotation_key => _}}} = resource
      ) do
    resource
  end

  def decorate_content_hash(resource) do
    update_in(
      resource,
      ~w(metadata annotations),
      fn annotations ->
        # Encode the content into strings.
        # This will then give us something that we can compute the hash of.
        {:ok, json_cont} = Jason.encode(resource)

        hash = :sha |> :crypto.hash(json_cont) |> Base.encode64()

        # Put the has into the annotations of metadata. Assuming json encoding stays
        # stable this provides a pretty cheap and easy way to
        # compare if the resources are coming from the same source.
        Map.put(annotations || %{}, @hash_annotation_key, hash)
      end
    )
  end
end
