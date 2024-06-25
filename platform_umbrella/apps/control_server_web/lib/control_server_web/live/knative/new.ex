defmodule ControlServerWeb.Live.KnativeNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Knative.Service
  alias ControlServer.Knative
  alias ControlServerWeb.Live.Knative.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    service = %Service{}
    changeset = Knative.change_service(service)

    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:project_id, params["project_id"])
     |> assign(:service, service)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.live_component
      module={FormComponent}
      service={@service}
      id="service-form"
      action={:new}
      title="New Knative Service"
      project_id={@project_id}
    />
    """
  end
end
