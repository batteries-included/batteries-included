defmodule ControlServer.KubeExt do
  @moduledoc """
  Module to make working with K8s client a little bit easier.

  get_or_create/2 is the most useful.
  """
  alias K8s.Client

  require Logger
  require Jason

  @hash_annotation_key "battery/hash"

  def get_or_create(%{"items" => item_list}) do
    {:ok, Enum.map(item_list, fn i -> get_or_create_single(i) end)}
  end

  def get_or_create(resource) do
    get_or_create_single(resource)
  end

  def apply(many) when is_list(many), do: Enum.map(many, &apply_single/1)
  def apply(single), do: apply_single(single)

  def apply_single(resource) do
    with {:ok, found} <- get_or_create(resource) do
      # Add the hash here means that we don't need
      # to recompute it if the hashes don't match.
      found = decorate_content_hash(found)
      resource = decorate_content_hash(resource)

      if get_hash(found) == get_hash(resource) do
        {:ok, found}
      else
        do_update(resource)
      end
    end
  end

  def get_hash(resource) do
    resource
    |> decorate_content_hash()
    |> get_in(["metadata", "annotations", @hash_annotation_key])
  end

  defp get_or_create_single(resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Creating or getting #{inspect(metadata)}")
    cluster_name = Bonny.Config.cluster_name()

    case resource
         |> Client.get()
         |> Client.run(cluster_name) do
      {:ok, _} = result ->
        result

      {:error, :not_found} ->
        Logger.debug("Create it is")

        res =
          resource
          |> decorate_content_hash()
          |> Client.create()
          |> Client.run(cluster_name)

        Logger.debug("Result = #{inspect(res)}")

        res

      unknown ->
        Logger.warning(
          "Got unknown result from get on #{inspect(metadata)} => #{inspect(unknown)}"
        )

        {:error, :unknown_result}
    end
  end

  defp do_update(resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Going to send update for #{inspect(metadata)}")
    cluster_name = Bonny.Config.cluster_name()
    resource |> Client.patch() |> Client.run(cluster_name)
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

        hash = :sha |> :crypto.hash(json_cont) |> Base.encode64()

        # Put the has into the annotations of metadata. Assuming json encoding stays
        # stable this provides a pretty cheap and easy way to
        # compare if the resources are coming from the same source.
        Map.put(annotations || %{}, @hash_annotation_key, hash)
      end
    )
  end
end
