defmodule KubeResources.Hashing do
  alias KubeResources.Hashing.Sanitizer
  alias KubeResources.Hashing.MapHMAC

  require Logger

  @hash_annotation_key "battery/hash"

  @spec key :: binary()
  def key, do: @hash_annotation_key

  @spec get_hash(any) :: binary()
  def get_hash(nil), do: "DEADBEEF"

  def get_hash(resource) do
    resource
    |> decorate()
    |> get_in(["metadata", "annotations", @hash_annotation_key]) || "DEADBEEF"
  end

  def decorate(%{"metadata" => %{"annotations" => %{@hash_annotation_key => _}}} = resource) do
    resource
  end

  def decorate(resource) do
    resource
    |> update_in(~w(metadata), fn meta -> Map.put_new(meta || %{}, "annotations", %{}) end)
    |> update_in(
      ~w(metadata annotations),
      fn annotations ->
        hash = compute_hash(resource)
        Map.put(annotations || %{}, @hash_annotation_key, hash)
      end
    )
  end

  def compute_hash(resource) do
    resource |> Sanitizer.sanitize() |> MapHMAC.get() |> Base.encode32()
  end

  def different?(applied, new) when is_map(applied) and is_map(new) do
    # Compare the hashes. It's important that by now all the resources have
    # their hashes computed and attached since we don't have access to memoize the hash
    applied_hash = applied |> decorate() |> get_hash()
    new_hash = new |> decorate() |> get_hash()
    applied_hash != new_hash
  end

  def different?(applied, new) do
    applied != new
  end

  def add_reference(resource, referenced_type, referenced_name, referenced_hash) do
    update_in(
      resource,
      [Access.key("metadata", %{}), Access.key("annotations", %{})],
      fn annotations ->
        Map.put(
          annotations || %{},
          ref_annotation_name(referenced_type, referenced_name),
          referenced_hash
        )
      end
    )
  end

  defp ref_annotation_name(referenced_type, referenced_name) do
    type_str = referenced_type |> to_string() |> String.replace(~r/[^[:alnum:]]+/, "")

    "battery.#{type_str}.ref/#{referenced_name}"
  end
end
