defmodule ControlServerWeb.Live.KnativeNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.MenuLayout

  alias ControlServer.Knative
  alias ControlServer.Knative.Service
  alias ControlServer.Batteries.Installer
  alias ControlServerWeb.Live.Knative.FormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    service = %Service{}
    changeset = Knative.change_service(service)

    {:ok,
     socket
     |> assign(:service, service)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def update(%{service: service} = assigns, socket) do
    Logger.info("Update")
    changeset = Knative.change_service(service)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_info({"service:save", %{"service" => service}}, socket) do
    new_path = ~p"/knative/services/#{service}/show"
    Installer.install!(:knative)

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.menu_layout>
      <:title>
        <.title>New service</.title>
      </:title>
      <div>
        <.live_component
          module={FormComponent}
          service={@service}
          id={@service.id || "new-service-form"}
          action={:new}
          save_target={self()}
        />
      </div>
    </.menu_layout>
    """
  end
end
