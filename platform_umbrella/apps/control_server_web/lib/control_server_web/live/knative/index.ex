defmodule ControlServerWeb.Live.KnativeServicesIndex do
  use ControlServerWeb, {:live_view, layout: :menu}

  import ControlServerWeb.LeftMenuPage
  import ControlServerWeb.KnativeServicesTable

  alias ControlServer.Knative

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :services, list_services())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :page_title, "Listing Services")
  end

  defp list_services do
    Knative.list_services()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.left_menu_page group={:devtools} active={:knative_serving}>
      <.section_title>
        Knative Services
      </.section_title>
      <.knative_services_table knative_services={@services} />

      <.h2>Actions</.h2>
      <.body_section>
        <.link navigate={~p"/knative/services/new"}>
          <.button>
            New Knative Service
          </.button>
        </.link>
      </.body_section>
    </.left_menu_page>
    """
  end
end
