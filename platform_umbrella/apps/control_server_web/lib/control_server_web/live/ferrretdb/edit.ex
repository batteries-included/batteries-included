defmodule ControlServerWeb.Live.FerretServiceEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.FerretDB
  alias ControlServerWeb.FerretDBFormComponent

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok, socket |> assign(ferret_service: FerretDB.get_ferret_service!(id)) |> assign_page_title()}
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: "Edit FerretDB Service", current_page: :data)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div :if={@ferret_service != nil}>
      <.live_component
        module={FerretDBFormComponent}
        ferret_service={@ferret_service}
        id={"edit-ferret-#{@ferret_service.id}"}
        action={:edit}
        title={@page_title}
      />
    </div>
    """
  end
end
