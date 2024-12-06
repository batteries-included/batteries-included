defmodule ControlServerWeb.Live.IstioVirtualServiceShow do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import CommonUI.Components.DataList

  alias KubeServices.KubeState

  def mount(%{"name" => name, "namespace" => namespace}, _session, socket) do
    {:ok,
     socket
     |> assign(name: name, namespace: namespace)
     |> assign_resource()
     |> assign_current_page()
     |> assign_page_title()}
  end

  defp assign_resource(%{assigns: %{name: name, namespace: namespace}} = socket) do
    assign(socket, virtual_service: KubeState.get!(:istio_virtual_service, namespace, name))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :net_sec)
  end

  defp assign_page_title(%{assigns: %{virtual_service: virtual_service}} = socket) do
    service_name = name(virtual_service)

    assign(socket, page_title: "Istio Virtual Service: " <> service_name)
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/istio/virtual_services"} />

    <.grid columns={%{sm: 1, xl: 2}}>
      <.panel title="Item Details" variant="gray">
        <.data_list>
          <:item title="Name">{name(@virtual_service)}</:item>
          <:item title="Namespace">{namespace(@virtual_service)}</:item>
          <:item title="UID">
            <.truncate_tooltip value={uid(@virtual_service)} length={16} />
          </:item>
        </.data_list>
      </.panel>
      <.panel title="Serving Details" class="overflow-none">
        <.data_list>
          <:item title="Host">
            <.truncate_tooltip value={format_hosts(@virtual_service)} length={36} />
          </:item>
          <:item title="Gateway">{format_gateways(@virtual_service)}</:item>
        </.data_list>
      </.panel>

      <.panel title="HTTP" class="col-span-2">
        <.table
          id="http-services-table"
          rows={@virtual_service |> spec() |> Map.get("http") |> Enum.with_index()}
        >
          <:col :let={{service, idx}} label="Name">{service |> Map.get("name") || idx}</:col>
          <:col :let={{service, _idx}} label="Match">
            <.match_display match={service |> Map.get("match") |> List.first()} />
          </:col>
          <:col :let={{service, _idx}} label="Routes">
            <.route_display routes={service |> Map.get("route")} />
          </:col>
        </.table>
      </.panel>
    </.grid>
    """
  end

  defp format_hosts(virtual_service) do
    virtual_service |> spec() |> Map.get("hosts") |> Enum.join(", ")
  end

  defp format_gateways(virtual_service) do
    virtual_service |> spec() |> Map.get("gateways") |> Enum.join(", ")
  end

  defp match_display(%{match: nil} = assigns) do
    ~H"""
    Any
    """
  end

  defp match_display(%{match: _} = assigns) do
    ~H"""
    <.flex column>
      <div :if={@match |> Map.get("gateways", []) != []}>
        <.h2 class="mt-0">gateways</.h2>
        <ul>
          <%= for gateway <- @match |> Map.get("gateways") do %>
            <li>{gateway}</li>
          <% end %>
        </ul>
      </div>

      <div :if={@match |> get_in(~w(authority prefix)) != nil}>
        <.h2 class="mt-0">Authority</.h2>
        Prefix: {@match |> get_in(~w(authority prefix))}
      </div>

      <div :if={@match |> get_in(~w(headers)) != nil}>
        <.h2 class="mt-0">Headers</.h2>
        <ul>
          <%= for {key, value} <- @match |> get_in(~w(headers)) do %>
            <li>{key}: {inspect(value)}</li>
          <% end %>
        </ul>
      </div>
    </.flex>
    """
  end

  defp route_display(%{routes: _} = assigns) do
    ~H"""
    <.flex column>
      <%= for route <- @routes do %>
        <div :if={route |> Map.get("destination", nil) != nil}>
          <.h2 class="mt-0">Destination</.h2>
          {route |> get_in(~w(destination host))} : {route
          |> get_in(~w(destination port number))}
        </div>

        <div :if={route |> Map.get("weight", nil) != nil}>
          <.h2 class="mt-0">Weight</.h2>
          {route |> Map.get("weight")}
        </div>

        <div :if={route |> Map.get("headers", nil) != nil}>
          <.h2 class="mt-0">Set Headers</.h2>

          <ul>
            <%= for {key, value} <- route |> get_in(~w(headers request set)) do %>
              <li>{key}: {inspect(value)}</li>
            <% end %>
          </ul>
        </div>
      <% end %>
    </.flex>
    """
  end
end
