defmodule CommonCore.RoboSRE.IssueStatus do
  @moduledoc """
  Ecto enum for RoboSRE issue status.
  """

  use CommonCore.Ecto.Enum,
    detected: "detected",
    analyzing: "analyzing",
    remediating: "remediating",
    monitoring: "monitoring",
    resolved: "resolved",
    failed: "failed"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Detected", :detected},
      {"Analyzing", :analyzing},
      {"Remediating", :remediating},
      {"Monitoring", :monitoring},
      {"Resolved", :resolved},
      {"Failed", :failed}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:detected), do: "Detected"
  def label(:analyzing), do: "Analyzing"
  def label(:remediating), do: "Remediating"
  def label(:monitoring), do: "Monitoring"
  def label(:resolved), do: "Resolved"
  def label(:failed), do: "Failed"
  def label(other), do: other |> Atom.to_string() |> String.capitalize()

  @spec in_progress?(t()) :: boolean()
  def in_progress?(:detected), do: true
  def in_progress?(:analyzing), do: true
  def in_progress?(:remediating), do: true
  def in_progress?(:monitoring), do: true
  def in_progress?(:resolved), do: false
  def in_progress?(:failed), do: false

  @spec terminal?(t()) :: boolean()
  def terminal?(status), do: not in_progress?(status)
end
