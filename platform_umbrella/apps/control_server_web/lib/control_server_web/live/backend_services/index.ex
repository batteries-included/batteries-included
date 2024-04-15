defmodule ControlServerWeb.Live.BackendServicesIndex do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.BackendServicesTable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_services() |> assign_current_page() |> assign_page_title()}
  end

  defp assign_services(socket) do
    assign(socket, :services, ControlServer.Backend.list_backend_services())
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :devtools)
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Listing Services")
  end

  defp new_url, do: "/backend_services/new"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/devtools"}>
      <.button variant="secondary" link={new_url()}>
        New Service
      </.button>
    </.page_header>

    <.panel title="Backend Services">
      <.backend_services_table rows={@services} />
    </.panel>
    """
  end
end
