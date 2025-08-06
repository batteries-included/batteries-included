defmodule ControlServerWeb.Live.GatewayRouteShow do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import CommonUI.Components.DataList

  alias KubeServices.KubeState

  def mount(%{"name" => name, "namespace" => namespace, "kind" => kind}, _session, socket) do
    {:ok,
     socket
     |> assign(name: name, namespace: namespace, kind: String.to_existing_atom(kind))
     |> assign_resource()
     |> assign_current_page()
     |> assign_page_title()}
  end

  defp assign_resource(%{assigns: %{name: name, namespace: namespace, kind: kind}} = socket) do
    assign(socket, route: KubeState.get!(kind, namespace, name))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :net_sec)
  end

  defp assign_page_title(%{assigns: %{route: route}} = socket) do
    service_name = name(route)

    assign(socket, page_title: "Gateway Route: " <> service_name)
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/gateway/routes"} />

    <.grid columns={%{sm: 1, xl: 2}}>
      <.panel title="Item Details" variant="gray">
        <.data_list>
          <:item title="Name">{name(@route)}</:item>
          <:item title="Namespace">{namespace(@route)}</:item>
          <:item title="UID">
            <.truncate_tooltip value={uid(@route)} length={16} />
          </:item>
        </.data_list>
      </.panel>
      <.panel title="Serving Details" class="overflow-none">
        <.data_list>
          <:item :if={@kind != :gateway_tcp_route} title="Hostnames">
            <.truncate_tooltip value={format_hostnames(@route)} length={36} />
          </:item>
          <:item title="Gateway">{format_gateways(@route)}</:item>
        </.data_list>
      </.panel>
    </.grid>
    """

    # TODO: add section for rules?
  end

  defp format_hostnames(route) do
    route |> spec() |> Map.get("hostnames") |> Enum.join(", ")
  end

  defp format_gateways(route) do
    route
    |> spec()
    |> Map.get("parentRefs")
    |> Enum.filter(&(Map.get(&1, "kind") == "Gateway"))
    |> Enum.map_join(", ", fn %{"name" => name, "namespace" => namespace} -> "#{namespace}/#{name}" end)
  end
end
