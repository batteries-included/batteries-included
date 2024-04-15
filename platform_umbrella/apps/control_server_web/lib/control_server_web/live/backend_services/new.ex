defmodule ControlServerWeb.Live.BackendNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Backend.Service
  alias ControlServerWeb.Live.BackendServices.FormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    service = %Service{virtual_size: "medium", num_instances: 1}
    {:ok, socket |> assign_service(service) |> assign_title()}
  end

  defp assign_service(socket, service) do
    assign(socket, service: service)
  end

  defp assign_title(socket) do
    assign(socket, title: "New Backend Service")
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.live_component
      module={FormComponent}
      service={@service}
      id="service-form"
      action={:new}
      title={@title}
    />
    """
  end
end
