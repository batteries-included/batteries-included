defmodule ControlServerWeb.Live.FerretServiceNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.FerretDB.FerretService
  alias ControlServerWeb.FerretDBFormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    ferret_service = %FerretService{instances: 1, virtual_size: "small"}
    {:ok, assign(socket, ferret_service: ferret_service, current_page: :data)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FerretDBFormComponent}
        ferret_service={@ferret_service}
        id="new-ferretdb-form"
        action={:new}
        title="New FerretDB MongoDB Compatible Service"
      />
    </div>
    """
  end
end
