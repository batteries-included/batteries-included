defmodule KubeServices.ResourceDeleter do
  @moduledoc false
  @behaviour KubeServices.ResourceDeleter.Behaviour

  alias KubeServices.ResourceDeleter.Worker

  @doc """
  Delete a K8s resource.
  """
  @spec delete(map) :: {:ok, map() | reference()} | {:error, any()}
  def delete(resource) do
    GenServer.call(Worker, {:delete, resource})
  end

  @doc """
  Undo the deletion of a K8s resource.
  """
  @spec undelete(CommonCore.Ecto.BatteryUUID.t()) :: any
  def undelete(deleted_resource_id) do
    GenServer.call(Worker, {:undelete, deleted_resource_id})
  end
end
