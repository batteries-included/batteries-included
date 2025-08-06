defmodule ControlServerWeb.Gateway.RoutesTable do
  @moduledoc false

  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  alias CommonCore.ApiVersionKind

  attr :rows, :list, default: []
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def routes_table(assigns) do
    ~H"""
    <.table id="routes-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={route} :if={!@abridged} label="ID">{uid(route)}</:col>
      <:col :let={route} label="Name">{name(route)}</:col>
      <:col :let={route} label="Namespace">{namespace(route)}</:col>
      <:col :let={route} :if={!@abridged} label="Hostnames">
        {format_hostnames(route)}
      </:col>

      <:action :let={route}>
        <.flex>
          <.button
            variant="minimal"
            link={show_url(route)}
            icon={:eye}
            id={"route_show_link_" <> to_html_id(route)}
          />
          <.tooltip target_id={"route_show_link_" <> to_html_id(route)}>
            Show Routes
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp format_hostnames(route) do
    case kind(route) do
      "TCPRoute" ->
        ""

      _ ->
        route |> spec() |> Map.get("hostnames") |> Enum.join(", ")
    end
  end

  defp show_url(route) do
    ns = namespace(route)
    name = name(route)
    kind = ApiVersionKind.resource_type!(route)
    ~p"/gateway/route/#{kind}/#{ns}/#{name}"
  end
end
