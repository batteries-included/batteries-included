defmodule KubeExt.ResourceVersion do
  @spec resource_version(map()) :: {:ok, binary()} | {:error, any()}
  def resource_version(%{"metadata" => %{"resourceVersion" => resource_version}}),
    do: {:ok, resource_version}

  def resource_version(%{"message" => _message}), do: {:error, :gone}
  def resource_version(_), do: {:error, "cant extract rv"}
end
