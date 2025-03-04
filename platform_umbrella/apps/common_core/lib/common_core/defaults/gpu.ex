defmodule CommonCore.Defaults.GPU do
  @moduledoc false
  @node_types [
    default: "None",
    any_nvidia: "Any Nvidia GPU",
    nvidia_a10: "Nvidia A10",
    nvidia_a100: "Nvidia A100",
    nvidia_h100: "Nvidia H100",
    nvidia_h200: "Nvidia H200"
  ]

  def node_type_keys, do: Keyword.keys(@node_types)

  def node_types_with_gpus, do: @node_types |> Keyword.delete(:default) |> Keyword.keys()

  def node_types_for_select, do: Enum.map(@node_types, fn {k, v} -> {v, k} end)
end
