defmodule CommonCore.Size do
  @moduledoc """
  Ecto enum for instance sizes used across the system.

  Backed by atoms in the Elixir code and used as an Ecto.Enum in schemas.
  """

  use CommonCore.Ecto.Enum,
    tiny: "tiny",
    small: "small",
    medium: "medium",
    large: "large",
    xlarge: "xlarge",
    huge: "huge",
    custom: "custom"

  @spec options() :: list({String.t(), t()})
  def options do
    __enum_map__()
    |> Map.keys()
    |> Enum.reject(&(&1 == :custom))
    |> Enum.map(fn k -> {k |> Atom.to_string() |> String.capitalize(), k} end)
  end

  @spec sizes() :: [atom()]
  def sizes do
    Map.keys(__enum_map__())
  end

  @spec label(t()) :: String.t()
  def label(value) when is_atom(value), do: value |> Atom.to_string() |> String.capitalize()
  def label(other), do: to_string(other)
end
