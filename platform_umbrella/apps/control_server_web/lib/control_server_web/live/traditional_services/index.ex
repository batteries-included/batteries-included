defmodule ControlServerWeb.Live.TraditionalServicesIndex do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.TraditionalServicesTable

  alias ControlServer.TraditionalServices

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Traditional Services")
     |> assign(:services, TraditionalServices.list_traditional_services())}
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/devtools"}>
      <.button variant="dark" icon={:plus} link={new_url()}>
        New Traditional Service
      </.button>
    </.page_header>

    <.panel title="All Services">
      <.traditional_services_table rows={@services} />
    </.panel>
    """
  end

  defp new_url, do: "/traditional_services/new"
end
