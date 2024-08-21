defmodule ControlServerWeb.Live.GroupBatteriesEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Batteries.Catalog
  alias ControlServer.Batteries
  alias ControlServerWeb.BatteriesFormComponent

  def mount(%{"id" => id}, _session, socket) do
    system_battery = Batteries.get_system_battery!(id)
    catalog_battery = Catalog.get(system_battery.type)

    {:ok,
     socket
     |> assign(:current_page, catalog_battery.group)
     |> assign(:page_title, "#{catalog_battery.name} Battery")
     |> assign(:system_battery, system_battery)
     |> assign(:catalog_battery, catalog_battery)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={BatteriesFormComponent}
      id="edit-battery-form"
      action={:edit}
      system_battery={@system_battery}
      catalog_battery={@catalog_battery}
    />
    """
  end
end
