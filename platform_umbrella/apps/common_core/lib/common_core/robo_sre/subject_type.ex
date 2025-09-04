defmodule CommonCore.RoboSRE.SubjectType do
  @moduledoc """
  Ecto enum for RoboSRE issue subject types.
  """

  use CommonCore.Ecto.Enum,
    pod: "pod",
    control_server: "control_server",
    service: "service"

  @spec options() :: list({String.t(), t()})
  def options do
    [
      {"Pod", :pod},
      {"Control Server", :control_server},
      {"Service", :service}
    ]
  end

  @spec label(t()) :: String.t()
  def label(:pod), do: "Pod"
  def label(:control_server), do: "Control Server"
  def label(:service), do: "Service"
  def label(other), do: other |> Atom.to_string() |> String.capitalize()
end
