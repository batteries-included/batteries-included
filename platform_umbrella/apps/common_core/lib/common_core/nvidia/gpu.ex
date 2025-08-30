defmodule CommonCore.Nvidia.GPU do
  @moduledoc false

  use CommonCore.Ecto.Enum,
    default: "None",
    any_nvidia: "Any Nvidia GPU",
    nvidia_a10: "Nvidia A10",
    nvidia_a100: "Nvidia A100",
    nvidia_h100: "Nvidia H100",
    nvidia_h200: "Nvidia H200"

  @spec keys() :: [atom()]
  def keys, do: Map.keys(__enum_map__())

  @spec with_gpus() :: [atom()]
  def with_gpus, do: __enum_map__() |> Map.keys() |> Enum.reject(&(&1 == :default))

  @spec options() :: [{String.t(), t()}]
  def options do
    Enum.map(__enum_map__(), fn {k, _v} ->
      {k |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize(), k}
    end)
  end
end
