defmodule ControlServerWeb.Live.TraditionalServicesEdit do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.TraditionalServices
  alias ControlServerWeb.Live.TraditionalServices.FormComponent

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Edit Traditional Service")}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    service = TraditionalServices.get_service!(id, preload: [:project])

    {:noreply, assign(socket, :service, service)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={FormComponent}
      service={@service}
      id="service-form"
      action={:edit}
      title={@page_title}
    />
    """
  end
end
