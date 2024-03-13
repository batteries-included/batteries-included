defmodule ControlServerWeb.Istio.VirtualServicesTable do
  @moduledoc false

  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  attr :rows, :list, default: []
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def virtual_services_table(assigns) do
    ~H"""
    <.table rows={@rows}>
      <:col :let={virtual_service} label="Name"><%= name(virtual_service) %></:col>
      <:col :let={virtual_service} label="Namespace"><%= namespace(virtual_service) %></:col>
      <:col :let={virtual_service} :if={!@abbridged} label="Hosts">
        <%= format_hosts(virtual_service) %>
      </:col>

      <:action :let={virtual_service}>
        <.flex>
          <.button
            variant="minimal"
            link={show_url(virtual_service)}
            icon={:eye}
            id={"show_vs_" <> to_html_id(virtual_service)}
          />

          <.tooltip target_id={"show_vs_" <> to_html_id(virtual_service)}>
            Show Virtual Service
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp format_hosts(virtual_service) do
    virtual_service |> spec() |> Map.get("hosts") |> Enum.join(", ")
  end

  defp show_url(virtual_service) do
    ns = namespace(virtual_service)
    name = name(virtual_service)
    ~p"/istio/virtual_service/#{ns}/#{name}"
  end
end
