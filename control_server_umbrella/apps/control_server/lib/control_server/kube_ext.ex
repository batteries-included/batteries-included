defmodule ControlServer.KubeExt do
  @moduledoc """
  Module to make working with K8s client a little bit easier.

  get_or_create/2 is the most useful.
  """
  require Logger
  require Jason

  @hash_annotation_key "battery/hash"

  def get_or_create(%{"items" => item_list}) do
    {:ok, Enum.map(item_list, fn i -> get_or_create_single(i) end)}
  end

  def get_or_create(resource) do
    get_or_create_single(resource)
  end

  def apply(resource) do
    {:ok, found} = get_or_create(resource)

    # Add the hash here means that we don't need
    # to recompute it if the hashes don't match.
    found = found |> decorate_content_hash()
    resource = resource |> decorate_content_hash()

    found_hash = get_hash(found)
    resource_hash = get_hash(resource)

    case found_hash == resource_hash do
      true ->
        {:ok, resource}

      false ->
        do_update(resource)
    end
  end

  defp get_or_create_single(resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Creating or getting #{inspect(metadata)}")
    cluster_name = Bonny.Config.cluster_name()

    case resource
         |> K8s.Client.get()
         |> K8s.Client.run(cluster_name) do
      {:ok, _} = result ->
        result

      _ ->
        Logger.debug("Create it is")

        resource
        |> decorate_content_hash()
        |> K8s.Client.create()
        |> K8s.Client.run(cluster_name)
    end
  end

  defp get_hash(resource) do
    resource
    |> decorate_content_hash()
    |> Map.get("metadata", %{})
    |> Map.get("annotations", %{})
    |> Map.get(@hash_annotation_key)
  end

  defp do_update(resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Going to send update for #{inspect(metadata)}")
    cluster_name = Bonny.Config.cluster_name()
    resource |> K8s.Client.patch() |> K8s.Client.run(cluster_name)
  end

  defp decorate_content_hash(
         %{"metadata" => %{"annotations" => %{@hash_annotation_key => _}}} = resource
       ) do
    resource
  end

  defp decorate_content_hash(resource) do
    update_in(
      resource,
      ~w(metadata annotations),
      fn annotations ->
        # Encode the content into strings.
        # This will then give us something that we can compute the hash of.
        {:ok, json_cont} = Jason.encode(resource)

        hash = :crypto.hash(:sha, json_cont) |> Base.encode64()

        # Put the has into the annotations of metadata. Assuming json encoding stays
        # stable this provides a pretty cheap and easy way to
        # compare if the resources are coming from the same source.
        Map.put(annotations || %{}, @hash_annotation_key, hash)
      end
    )
  end
end
