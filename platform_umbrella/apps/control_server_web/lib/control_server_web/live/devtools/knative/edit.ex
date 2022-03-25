defmodule ControlServerWeb.Live.KnativeEdit do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Knative
  alias ControlServerWeb.Live.Knative.FormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :service, Knative.get_service!(id))}
  end

  @impl true
  def handle_info({"service:save", %{"service" => service}}, socket) do
    new_path = Routes.knative_services_index_path(socket, :index)
    Logger.debug("updated cluster = #{inspect(service)} new_path = #{new_path}")

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Edit Service</.title>
      </:title>
      <div>
        <.live_component
          module={FormComponent}
          service={@service}
          id={@service.id || "edit-cluster-form"}
          action={:edit}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end
