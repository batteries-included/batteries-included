defmodule KubeExt do
  alias K8s.Client

  alias KubeExt.Hashing

  require Logger
  require Jason

  def get_or_create(connection, %{"items" => item_list}) do
    {:ok, Enum.map(item_list, fn i -> get_or_create_single(connection, i) end)}
  end

  def get_or_create(connection, resource), do: get_or_create_single(connection, resource)

  def maybe_apply(resource) when is_list(resource),
    do: apply(KubeExt.ConnectionPool.get(), resource)

  def maybe_apply(connection, many) when is_list(many),
    do: Enum.map(many, fn resource -> apply_single(connection, resource) end)

  def maybe_apply(connection, single), do: apply_single(connection, single)

  defp apply_single(connection, resource) do
    with {:ok, found} <- get_or_create(connection, resource) do
      # Add the hash here means that we don't need
      # to recompute it if the hashes don't match.
      found = Hashing.decorate_content_hash(found)
      resource = Hashing.decorate_content_hash(resource)

      if Hashing.get_hash(found) == Hashing.get_hash(resource) do
        {:ok, found}
      else
        update_single(connection, resource)
      end
    end
  end

  defp get_or_create_single(connection, resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Creating or getting #{inspect(metadata)}")

    get_operation = Client.get(resource)

    case Client.run(connection, get_operation) do
      {:ok, _} = result ->
        result

      {:error, %Client.APIError{reason: "NotFound"}} ->
        Logger.debug("Create it is")

        create_operation =
          resource
          |> Hashing.decorate_content_hash()
          |> Client.create()

        res = Client.run(connection, create_operation)

        Logger.warning("Result = #{inspect(res)}")

        res

      unknown ->
        Logger.warning(
          "Got unknown result from get on #{inspect(metadata)} => #{inspect(unknown)}"
        )

        {:error, :unknown_result}
    end
  end

  defp update_single(connection, resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Going to send update for #{inspect(metadata)}")

    patch_operation = Client.patch(resource)
    Client.run(connection, patch_operation)
  end
end
