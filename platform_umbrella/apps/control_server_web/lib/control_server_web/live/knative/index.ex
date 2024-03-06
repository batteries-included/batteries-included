defmodule ControlServerWeb.Live.KnativeServicesIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServer.Knative
  import ControlServerWeb.KnativeServicesTable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_services() |> assign_current_page()}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Listing Services")
  end

  defp assign_services(socket) do
    assign(socket, :services, list_services())
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :devtools)
  end

  defp new_url, do: ~p"/knative/services/new"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_button={%{link_type: "live_redirect", to: "/devtools"}}>
      <:menu>
        <.button variant="secondary" link={new_url()}>
          New Service
        </.button>
      </:menu>
    </.page_header>

    <.panel title="Serverless Services">
      <.knative_services_table rows={@services} />
    </.panel>
    """
  end
end
