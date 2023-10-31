defmodule ControlServerWeb.Live.KnativeServicesIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServer.Knative
  import ControlServerWeb.KnativeServicesTable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_services(socket)}
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

  defp new_url, do: ~p"/knative/services/new"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_button={%{link_type: "live_redirect", to: "/devtools"}} />

    <.panel>
      <:title>Knative Serverless</:title>
      <:top_right>
        <PC.button to={new_url()} link_type="live_redirect" label="New Service" />
      </:top_right>
      <.knative_services_table rows={@services} />
    </.panel>
    """
  end
end
