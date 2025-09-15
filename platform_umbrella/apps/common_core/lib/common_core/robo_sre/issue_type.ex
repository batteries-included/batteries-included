defmodule CommonCore.RoboSRE.IssueType do
  @moduledoc """
  Ecto enum for RoboSRE issue types.
  """

  use CommonCore.Ecto.Enum,
    stuck_kubestate: "stuck_kubestate",
    stale_resource: "stale_resource"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Stuck KubeState", :stuck_kubestate},
      {"Stale Resource", :stale_resource}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:stuck_kubestate), do: "Stuck KubeState"
  def label(:stale_resource), do: "Stale Resource"

  def label(other) do
    other
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  def open_statuses do
    [:detected, :analyzing, :planning, :remediating, :verifying]
  end
end
