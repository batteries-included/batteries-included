defmodule ControlServerWeb.Live.GatewayRoutesIndex do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Gateway.RoutesTable

  alias KubeServices.SystemState.SummaryGateway

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_routes()
     |> assign_current_page()
     |> assign_page_title()}
  end

  defp assign_routes(socket) do
    # TODO: use summary
    assign(socket, routes: SummaryGateway.routes())
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :net_sec)
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: "Gateway Routes")
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/net_sec"} />

    <.panel title="Routes"><.routes_table rows={@routes} /></.panel>
    """
  end
end
