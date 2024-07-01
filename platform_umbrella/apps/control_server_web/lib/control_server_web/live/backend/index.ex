defmodule ControlServerWeb.Live.BackendIndex do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.BackendServicesTable

  alias ControlServer.Backend

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Backend Services")
     |> assign(:services, Backend.list_backend_services())}
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/devtools"}>
      <.button variant="secondary" link={new_url()}>
        New Service
      </.button>
    </.page_header>

    <.panel title="All Services">
      <.backend_services_table rows={@services} />
    </.panel>
    """
  end

  defp new_url, do: "/backend/services/new"
end
