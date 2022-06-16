defmodule KubeExt do
  alias K8s.Client
  alias K8s.Resource
  alias KubeExt.Hashing

  require Logger
  require Jason

  def uid(resource) do
    get_in(resource, ~w(metadata uid))
  end

  # Get or create single matches on lots of things that could mean 404.
  # These matches are more comprehensive than the typespec on K8s.
  # Could be that old versions had different types, or it could be
  # K8s' typespec is wrong, or it could be both.
  @dialyzer {:nowarn_function, get_or_create_single: 2}

  def get_or_create(connection, %{"items" => item_list}) do
    {:ok, Enum.map(item_list, fn i -> get_or_create_single(connection, i) end)}
  end

  def get_or_create(connection, resource), do: get_or_create_single(connection, resource)

  def maybe_apply(resource) when is_list(resource),
    do: maybe_apply(KubeExt.ConnectionPool.get(), resource)

  def maybe_apply(single), do: apply_single(KubeExt.ConnectionPool.get(), single)

  def maybe_apply(connection, many) when is_list(many) do
    many
    |> Enum.map(fn resource -> maybe_apply(connection, resource) end)
    |> Enum.flat_map(&List.wrap/1)
    |> Enum.reduce(
      {:ok, 0},
      fn result, acc ->
        case result do
          {:ok, _} ->
            increment_ok(acc)

          :ok ->
            increment_ok(acc)

          _ ->
            result
        end
      end
    )
  end

  def maybe_apply(connection, single), do: apply_single(connection, single)

  def apply_single(_connection, nil = _resouce), do: {:ok, nil}

  def apply_single(_connection, [] = _resource), do: {:ok, []}

  def apply_single(connection, resource) do
    with {:ok, found} <- get_or_create(connection, resource) do
      # Add the hash here means that we don't need
      # to recompute it if the hashes don't match.
      found = Hashing.decorate_content_hash(found)
      resource = Hashing.decorate_content_hash(resource)

      if Hashing.different?(found, resource) do
        update_single(connection, resource)
      else
        {:ok, found}
      end
    end
  end

  defp get_or_create_single(connection, resource) do
    metadata = Map.get(resource, "metadata")
    Logger.debug("Creating or getting #{inspect(metadata)}")

    get_operation = Client.get(resource)

    client_result = Client.run(connection, get_operation)

    case client_result do
      {:ok, _} ->
        client_result

      {_, :not_found} ->
        create(connection, resource)

      {:error, %HTTPoison.Response{status_code: 404}} ->
        create(connection, resource)

      {:error, %Client.APIError{reason: "NotFound"}} ->
        create(connection, resource)

      {:error, %K8s.Operation.Error{message: "NotFound"}} ->
        create(connection, resource)

      unknown ->
        Logger.warning(
          "Got unknown result from get on #{inspect(metadata)} => #{inspect(unknown)}"
        )

        {:error, :unknown_result}
    end
  end

  defp create(connection, resource) do
    Logger.info(
      "Going to create Kind: #{Resource.kind(resource)} Name: #{Resource.name(resource)}"
    )

    create_operation =
      resource
      |> Hashing.decorate_content_hash()
      |> Client.create()

    create_result = Client.run(connection, create_operation)

    Logger.debug("Create Result: #{inspect(create_result)}")

    create_result
  end

  defp update_single(connection, resource) do
    Logger.info(
      "Going to patch Kind: #{Resource.kind(resource)} Name: #{Resource.name(resource)} Namespace: #{Resource.namespace(resource)}"
    )

    operation = Client.patch(resource)
    result = Client.run(connection, operation)
    Logger.debug("Update result: #{inspect(result)}")
    result
  end

  defp increment_ok({:ok, cnt}), do: {:ok, cnt + 1}
  defp increment_ok(err), do: err

  def cluster_type, do: Application.get_env(:kube_ext, :cluster_type, :dev)
end
