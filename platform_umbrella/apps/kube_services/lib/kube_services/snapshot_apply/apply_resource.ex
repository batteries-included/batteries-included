defmodule KubeServices.SnapshotApply.ApplyResource do
  @moduledoc """
  Handles apply K8s resources.
  """

  # Get or create single matches on lots of things that could mean 404.
  # These matches are more comprehensive than the typespec on K8s.
  # Could be that old versions had different types, or it could be
  # K8s' typespec is wrong, or it could be both.
  use TypedStruct

  alias CommonCore.Resources.Hashing
  alias K8s.Client
  alias K8s.Resource

  require Logger

  @dialyzer {:nowarn_function, get_or_create_single: 2}

  defmodule ResourceState do
    @moduledoc """
    Simple struct to hold information about the last time we
    tried to apply this resource spec to kubernetes.
    """
    typedstruct do
      field :resource, map()
      field :last_result, any()
    end

    @doc """
    Determines if a resource needs to be applied.
    """
    @spec needs_apply?(ResourceState.t(), map()) :: boolean()
    def needs_apply?(%ResourceState{} = resource_state, new_resource) do
      # If the last try was an error then we always try and sync.
      # otherwise if there's been something that changed in the database.
      !ok?(resource_state) || Hashing.different?(resource(resource_state), new_resource)
    end

    @doc """
    Determine if a resource is ok.
    """
    @spec ok?(ResourceState.t()) :: boolean()
    def ok?(%ResourceState{last_result: last_result}), do: result_ok?(last_result)

    defp result_ok?(:ok), do: true
    defp result_ok?({:ok, _}), do: true
    defp result_ok?(result) when is_list(result), do: Enum.all?(result, &result_ok?/1)
    defp result_ok?(_), do: false

    defp resource(%ResourceState{resource: res}), do: res
  end

  @doc """
  Apply a k8s resource if needed.
  """
  @spec apply(K8s.Conn.t(), map()) :: ResourceState.t()
  def apply(connection, resource) do
    apply_result = maybe_apply(connection, resource)
    %ResourceState{last_result: apply_result, resource: resource}
  end

  @doc """
  Determine if a resource needs to be updated / applied.
  """
  @spec needs_apply?(ResourceState.t(), map()) :: boolean()
  def needs_apply?(%ResourceState{} = resource_state, new_resource),
    do: ResourceState.needs_apply?(resource_state, new_resource)

  @doc """
  Mark a resource as being successfully applied and not in need of an apply.
  """
  @spec verify(K8s.Conn.t(), map()) :: ResourceState.t()
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

  defp apply_single(_connection, nil = _resource), do: {:ok, nil}

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

      {:error, %{status_code: 404}} ->
        create(connection, resource)

      {:error, %Client.APIError{reason: "NotFound"}} ->
        create(connection, resource)

      {:error, %K8s.Operation.Error{message: "NotFound"}} ->
        create(connection, resource)

      {:error, %K8s.Client.HTTPError{message: "HTTP Error 404"}} ->
        create(connection, resource)

      unknown ->
        Logger.warning("Got unknown result from get on #{inspect(metadata)} => #{inspect(unknown)}")

        {:error, :unknown_result}
    end
  end

  defp create(connection, resource) do
    Logger.info("Going to create Kind: #{Resource.kind(resource)} Name: #{Resource.name(resource)}")

    resource
    |> Client.create()
    |> Client.put_conn(connection)
    |> Client.run()
  end

  defp update_single(connection, resource) do
    Logger.info(
      "Going to apply Kind: #{Resource.kind(resource)} Name: #{Resource.name(resource)} Namespace: #{Resource.namespace(resource)}"
    )

    resource
    |> Client.apply()
    |> Client.put_conn(connection)
    |> Client.run()
  end

  defp increment_ok({:ok, cnt}), do: {:ok, cnt + 1}
  defp increment_ok(err), do: err
end
