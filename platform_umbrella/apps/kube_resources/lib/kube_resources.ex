defmodule KubeResources do
  @moduledoc """
  Documentation for `KubeResources`.
  """

  import K8s.Resource.FieldAccessors

  require Logger

  def unique_kinds(materialized_service_map) do
    materialized_service_map
    |> Map.values()
    |> Enum.flat_map(&extract/1)
    |> Enum.uniq()
  end

  defp extract(list_objects) when is_list(list_objects) do
    Enum.map(list_objects, &extract_single/1)
  end

  defp extract(obj) when is_map(obj), do: [extract_single(obj)]
  defp extract(nil), do: []

  defp extract_single(obj), do: {api_version(obj), kind(obj)}
end
