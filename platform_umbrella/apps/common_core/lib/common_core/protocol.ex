defmodule CommonCore.Protocol do
  @moduledoc """
  Ecto enum for network protocols supported by ports.
  """

  use CommonCore.Ecto.Enum,
    http: "http",
    http2: "http2",
    tcp: "tcp"

  @doc """
  Returns protocol options for use in forms and select inputs.
  Returns a list of {display_name, atom_value} tuples.
  """
  def options do
    [
      {"HTTP", :http},
      {"HTTP2", :http2},
      {"TCP", :tcp}
    ]
  end

  def k8s_protocol(_), do: "TCP"
end
