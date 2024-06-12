defmodule ControlServerWeb.GroupBatteries.EditLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Batteries.Catalog
  alias ControlServerWeb.BatteriesFormComponent

  def mount(%{"battery_type" => battery_type}, _session, socket) do
    battery = Catalog.get(battery_type)

    {:ok,
     socket
     |> assign(:battery, battery)
     |> assign(:current_page, battery.group)
     |> assign(:page_title, "#{battery.name} Battery")}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    {:noreply,
     socket
     |> put_flash(:global_success, "Battery has been updated")
     |> push_navigate(to: ~p"/batteries/#{socket.assigns.battery.group}")}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={BatteriesFormComponent}
      id="edit-batteries-form"
      action={:edit}
      battery={@battery}
    />
    """
  end
end
