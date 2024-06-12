defmodule ControlServerWeb.GroupBatteries.IndexLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Batteries.Catalog
  alias ControlServer.Batteries
  alias EventCenter.Database, as: DatabaseEventCenter

  def mount(%{"group" => group}, _session, socket) do
    :ok = DatabaseEventCenter.subscribe(:system_battery)
    group = Catalog.group(group)

    {:ok,
     socket
     |> assign(:group, group)
     |> assign(:current_page, group.id)
     |> assign(:page_title, "#{group.name} Batteries")
     |> assign(:catalog_batteries, Catalog.all(group.id))
     |> assign_system_batteries(group)}
  end

  defp assign_system_batteries(socket, group) do
    system_batteries =
      group.id
      |> Batteries.list_system_batteries_for_group()
      |> Map.new(&{&1.type, &1})

    assign(socket, :system_batteries, system_batteries)
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={"/#{@group.id}"} />

    <.grid columns={%{sm: 1, md: 2, xl: 3}}>
      <.panel :for={battery <- @catalog_batteries} title={battery.name}>
        <:menu>
          <%= if Map.has_key?(@system_batteries, battery.type) do %>
            <div class="flex items-center justify-between flex-1">
              <.badge minimal label="ACTIVE" class="bg-green-500 text-white" />

              <.button link={~p"/batteries/#{battery.group}/edit/#{battery.type}"} icon={:pencil}>
                Edit
              </.button>
            </div>
          <% else %>
            <.button link={~p"/batteries/#{battery.group}/new/#{battery.type}"} icon={:bolt}>
              Install
            </.button>
          <% end %>
        </:menu>

        <p class="text-sm"><%= battery.description %></p>
      </.panel>
    </.grid>
    """
  end
end
