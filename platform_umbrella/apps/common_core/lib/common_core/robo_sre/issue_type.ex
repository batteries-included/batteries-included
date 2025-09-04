defmodule CommonCore.RoboSRE.IssueType do
  @moduledoc """
  Ecto enum for RoboSRE issue types.
  """

  use CommonCore.Ecto.Enum,
    pod_crash: "pod_crash",
    stuck_kubestate: "stuck_kubestate",
    service_unavailable: "service_unavailable"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Pod Crash", :pod_crash},
      {"Stuck KubeState", :stuck_kubestate},
      {"Service Unavailable", :service_unavailable}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:pod_crash), do: "Pod Crash"
  def label(:stuck_kubestate), do: "Stuck KubeState"
  def label(:service_unavailable), do: "Service Unavailable"

  def label(other),
    do:
      other |> Atom.to_string() |> String.replace("_", " ") |> String.split() |> Enum.map_join(" ", &String.capitalize/1)
end
