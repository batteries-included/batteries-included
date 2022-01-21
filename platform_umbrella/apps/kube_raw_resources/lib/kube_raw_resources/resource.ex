defmodule KubeRawResources.Resource do
  alias KubeExt.Hashing

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
    apply_result = KubeExt.maybe_apply(connection, resource)
    %ResourceState{last_result: apply_result, resource: resource}
  end

  def needs_apply(%ResourceState{} = resource_state, new_resource),
    do: ResourceState.needs_apply(resource_state, new_resource)

  def verify(_connection, new_resource) do
    %ResourceState{last_result: :ok, resource: new_resource}
  end
end
