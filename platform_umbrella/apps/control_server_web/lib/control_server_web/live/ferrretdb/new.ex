defmodule ControlServerWeb.Live.FerretServiceNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.FerretDB.FerretService
  alias ControlServerWeb.FerretDBFormComponent

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    ferret_service = %FerretService{
      instances: 1,
      virtual_size: Atom.to_string(KubeServices.SystemState.SummaryBatteries.default_size())
    }

    {:ok,
     socket
     |> assign(:project_id, params["project_id"])
     |> assign(:ferret_service, ferret_service)
     |> assign(:current_page, :data)}
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
        title="New FerretDB/MongoDB Compatible Service"
        project_id={@project_id}
      />
    </div>
    """
  end
end
