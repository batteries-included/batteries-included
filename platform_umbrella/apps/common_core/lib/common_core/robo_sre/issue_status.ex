defmodule CommonCore.RoboSRE.IssueStatus do
  @moduledoc """
  Ecto enum for RoboSRE issue status.
  """

  use CommonCore.Ecto.Enum,
    detected: "detected",
    analyzing: "analyzing",
    planning: "planning",
    remediating: "remediating",
    verifying: "verifying",
    resolved: "resolved",
    failed: "failed"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Detected", :detected},
      {"Analyzing", :analyzing},
      {"Planning", :planning},
      {"Remediating", :remediating},
      {"Verifying", :verifying},
      {"Resolved", :resolved},
      {"Failed", :failed}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:detected), do: "Detected"
  def label(:analyzing), do: "Analyzing"
  def label(:planning), do: "Planning"
  def label(:remediating), do: "Remediating"
  def label(:verifying), do: "Verifying"
  def label(:resolved), do: "Resolved"
  def label(:failed), do: "Failed"
  def label(other), do: other |> Atom.to_string() |> String.capitalize()
end
