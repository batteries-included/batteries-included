defmodule CommonCore.RoboSRE.HandlerType do
  @moduledoc false
  use CommonCore.Ecto.Enum,
    stale_resource: "StaleResource"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Stale Resource", :stale_resource}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:stale_resource), do: "Stale Resource"
  def label(other), do: other |> Atom.to_string() |> String.replace("_", " ") |> String.capitalize()
end
