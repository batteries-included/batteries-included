defmodule ControlServerWeb.Live.BackendEdit do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Backend
  alias ControlServerWeb.Live.Backend.FormComponent

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "Edit Backend Service")}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    service = Backend.get_service!(id, preload: [:project])

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
