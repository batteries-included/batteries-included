defmodule ControlServerWeb.Live.KnativeNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias CommonCore.Knative.Service
  alias ControlServer.Knative
  alias ControlServerWeb.Live.Knative.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    service = %Service{}
    changeset = Knative.change_service(service)

    {:ok,
     socket
     |> assign(:service, service)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveView
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

  @impl Phoenix.LiveView
  def handle_info({"service:save", %{"service" => service}}, socket) do
    new_path = ~p"/knative/services/#{service}/show"

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.h1>New Knative Serverless</.h1>
      <.live_component
        module={FormComponent}
        service={@service}
        id={@service.id || "new-service-form"}
        action={:new}
        save_target={self()}
      />
    </div>
    """
  end
end
