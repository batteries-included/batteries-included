defmodule KubeServices.ResourceDeleter.Behaviour do
  @moduledoc """
  Behaviour for resource deletion modules.
  """

  @doc """
  Delete a K8s resource.
  """
  @callback delete(map()) :: {:ok, map() | reference()} | {:error, any()}
end
