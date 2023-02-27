defmodule ControlServerWeb.Live.KnativeServicesIndex do
  use ControlServerWeb, {:live_view, layout: :fresh}

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
    <.h1>
      Knative Services
    </.h1>
    <.knative_services_table knative_services={@services} />

    <.h2 variant="fancy">Actions</.h2>
    <.card>
      <div class="grid md:grid-cols-1 gap-6">
        <.link navigate={~p"/knative/services/new"} class="block w-full">
          <.button class="w-full">
            New Knative Service
          </.button>
        </.link>
      </div>
    </.card>
    """
  end
end
