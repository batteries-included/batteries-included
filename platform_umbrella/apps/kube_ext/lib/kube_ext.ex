defmodule KubeExt do
  alias K8s.Client

  alias KubeExt.Hashing

  require Logger
  require Jason

  def get_or_create(%{"items" => item_list}) do
    {:ok, Enum.map(item_list, fn i -> get_or_create_single(i) end)}
  end

  def get_or_create(resource), do: get_or_create_single(resource)

  def apply(many) when is_list(many), do: Enum.map(many, &apply_single/1)
  def apply(single), do: apply_single(single)

  defp apply_single(resource) do
    with {:ok, found} <- get_or_create(resource) do
      # Add the hash here means that we don't need
      # to recompute it if the hashes don't match.
      found = Hashing.decorate_content_hash(found)
      resource = Hashing.decorate_content_hash(resource)

      if Hashing.get_hash(found) == Hashing.get_hash(resource) do
        {:ok, found}
      else
        update_single(resource)
      end
    end
  end

  defp get_or_create_single(resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Creating or getting #{inspect(metadata)}")

    case resource
         |> Client.get()
         |> Client.run(:default) do
      {:ok, _} = result ->
        result

      {:error, :not_found} ->
        Logger.debug("Create it is")

        res =
          resource
          |> Hashing.decorate_content_hash()
          |> Client.create()
          |> Client.run(:default)

        Logger.warning("Result = #{inspect(res)}")

        res

      unknown ->
        Logger.warning(
          "Got unknown result from get on #{inspect(metadata)} => #{inspect(unknown)}"
        )

        {:error, :unknown_result}
    end
  end

  defp update_single(resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Going to send update for #{inspect(metadata)}")
    resource |> Client.patch() |> Client.run(:default)
  end
end
