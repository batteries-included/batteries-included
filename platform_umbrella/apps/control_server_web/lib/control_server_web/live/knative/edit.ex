defmodule ControlServerWeb.Live.KnativeEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Knative
  alias ControlServerWeb.Live.Knative.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_page, :devtools)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :service, Knative.get_service!(id))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FormComponent}
        service={@service}
        id="service-form"
        action={:edit}
        title="Edit Knative Service"
      />
    </div>
    """
  end
end
