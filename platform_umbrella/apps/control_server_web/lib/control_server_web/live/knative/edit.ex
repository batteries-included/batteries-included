defmodule ControlServerWeb.Live.KnativeEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias ControlServer.Knative
  alias ControlServerWeb.Live.Knative.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :service, Knative.get_service!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({"service:save", %{"service" => service}}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/knative/services/#{service}/show")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FormComponent}
        service={@service}
        id={@service.id || "edit-cluster-form"}
        action={:edit}
        save_target={self()}
      />
    </div>
    """
  end
end
