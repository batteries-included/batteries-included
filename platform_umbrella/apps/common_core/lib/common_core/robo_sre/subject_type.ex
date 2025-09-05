defmodule CommonCore.RoboSRE.SubjectType do
  @moduledoc """
  Ecto enum for RoboSRE issue subject types.
  """

  use CommonCore.Ecto.Enum,
    pod: "pod",
    control_server: "control_server",
    cluster_resource: "cluster_resource"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Pod", :pod},
      {"Control Server", :control_server},
      {"Cluster Resource", :cluster_resource}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:pod), do: "Pod"
  def label(:control_server), do: "Control Server"
  def label(:cluster_resource), do: "Cluster Resource"
  def label(other), do: other |> Atom.to_string() |> String.capitalize()
end
