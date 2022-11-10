defmodule KubeExt.ResourceVersion do
  def sortable_resource_version(resource) do
    with {:ok, resource_version} <- resource_version(resource),
         {int_resource_version, ""} <- Integer.parse(resource_version) do
      -int_resource_version
    else
      {:error, _} -> 0
      _ -> 0
    end
  end

  @spec resource_version(map()) :: {:ok, binary()} | {:error, any()}
  def resource_version(%{"metadata" => %{"resourceVersion" => resource_version}}),
    do: {:ok, resource_version}

  def resource_version(%{"message" => _message}), do: {:error, :gone}
  def resource_version(_), do: {:error, "cant extract rv"}
end
