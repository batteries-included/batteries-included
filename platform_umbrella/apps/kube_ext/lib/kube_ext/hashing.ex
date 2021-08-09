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
    resource
    |> update_in(~w(metadata), fn meta -> Map.put_new(meta || %{}, "annotations", %{}) end)
    |> update_in(
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

  def different?(applied_list, new_list)
      when is_list(applied_list) and is_list(new_list) do
    applied_list
    |> Enum.zip(new_list)
    |> Enum.any?(fn {applied, new} ->
      different?(applied, new)
    end)
  end

  def different?(applied, new) when is_map(applied) and is_map(new) do
    # Compare the hashes. It's important that by now all the resources have
    # their hashes computed and attached since we don't have access to memoize the hash
    applied_hash = applied |> decorate_content_hash() |> get_hash()
    new_hash = new |> decorate_content_hash() |> get_hash()
    applied_hash != new_hash
  end

  def different?(applied, new) do
    applied != new
  end
end
