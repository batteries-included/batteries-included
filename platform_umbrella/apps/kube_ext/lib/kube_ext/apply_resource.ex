defmodule KubeExt.ApplyResource do
  # Get or create single matches on lots of things that could mean 404.
  # These matches are more comprehensive than the typespec on K8s.
  # Could be that old versions had different types, or it could be
  # K8s' typespec is wrong, or it could be both.
  @dialyzer {:nowarn_function, get_or_create_single: 2}

  alias KubeExt.Hashing
  alias K8s.Client
  alias K8s.Resource

  require Logger

  defmodule ResourceState do
    @moduledoc """
    Simple struct to hold information about the last time we
    tried to apply this resource spec to kubernetes.
    """
    defstruct [:resource, :last_result]

    def needs_apply(%ResourceState{} = resource_state, new_resource) do
      # If the last try was an error then we always try and sync.
      # otherwise if there's been something that changed in the database.
      !ok?(resource_state) || Hashing.different?(resource(resource_state), new_resource)
    end

    def ok?(%ResourceState{last_result: last_result}), do: result_ok?(last_result)

    defp result_ok?(:ok), do: true
    defp result_ok?({:ok, _}), do: true
    defp result_ok?(result) when is_list(result), do: Enum.all?(result, &result_ok?/1)
    defp result_ok?(_), do: false

    defp resource(%ResourceState{resource: res}), do: res
  end

  def apply(connection, resource) do
    apply_result = maybe_apply(connection, resource)
    %ResourceState{last_result: apply_result, resource: resource}
  end

  def needs_apply(%ResourceState{} = resource_state, new_resource),
    do: ResourceState.needs_apply(resource_state, new_resource)

  def verify(_connection, new_resource) do
    %ResourceState{last_result: :ok, resource: new_resource}
  end

  defp get_or_create(connection, %{"items" => item_list}) do
    {:ok, Enum.map(item_list, fn i -> get_or_create_single(connection, i) end)}
  end

  defp get_or_create(connection, resource), do: get_or_create_single(connection, resource)

  defp maybe_apply(connection, many) when is_list(many) do
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

  defp maybe_apply(connection, single), do: apply_single(connection, single)

  defp apply_single(_connection, nil = _resouce), do: {:ok, nil}

  defp apply_single(_connection, [] = _resource), do: {:ok, []}

  defp apply_single(connection, resource) do
    with {:ok, found} <- get_or_create(connection, resource) do
      # Add the hash here means that we don't need
      # to recompute it if the hashes don't match.
      found = Hashing.decorate(found)
      resource = Hashing.decorate(resource)

      if Hashing.different?(found, resource) do
        update_single(connection, resource)
      else
        {:ok, found}
      end
    end
  end

  defp get_or_create_single(connection, resource) do
    metadata = Map.get(resource, "metadata")

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

    Client.create(resource)
    |> Client.put_conn(connection)
    |> K8s.Client.run()
  end

  defp update_single(connection, resource) do
    Logger.info(
      "Going to apply Kind: #{Resource.kind(resource)} Name: #{Resource.name(resource)} Namespace: #{Resource.namespace(resource)}"
    )

    Client.apply(resource)
    |> Client.put_conn(connection)
    |> K8s.Client.run()
  end

  defp increment_ok({:ok, cnt}), do: {:ok, cnt + 1}
  defp increment_ok(err), do: err
end
