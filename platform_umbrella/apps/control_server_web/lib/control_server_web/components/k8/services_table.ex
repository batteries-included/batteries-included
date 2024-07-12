defmodule ControlServerWeb.ServicesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  attr :services, :list, required: true
  attr :id, :string, default: "services_table"

  def services_table(assigns) do
    ~H"""
    <.table rows={@services || []} id={@id} row_click={&JS.navigate(resource_path(&1))}>
      <:col :let={service} label="Name"><%= name(service) %></:col>
      <:col :let={service} label="Namespace"><%= namespace(service) %></:col>
      <:col :let={service} label="Cluster IP"><%= get_in(service, ~w(spec clusterIP)) %></:col>
      <:col :let={service} label="Ports"><%= display_ports(service) %></:col>
    </.table>
    """
  end

  defp display_ports(service) do
    service
    |> ports()
    |> Enum.map_join(", ", fn p -> Map.get(p, "port", 0) end)
  end
end
