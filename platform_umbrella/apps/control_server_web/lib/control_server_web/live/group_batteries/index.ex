defmodule ControlServerWeb.Live.GroupBatteriesIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Batteries.Catalog
  alias ControlServer.Batteries
  alias EventCenter.Database, as: DatabaseEventCenter

  def mount(%{"group" => group}, _session, socket) do
    if connected?(socket) do
      :ok = DatabaseEventCenter.subscribe(:system_battery)
    end

    group = Catalog.group(group)
    core_battery = KubeServices.SystemState.SummaryBatteries.core_battery()

    {:ok,
     socket
     |> assign(:group, group)
     |> assign(:current_page, group.type)
     |> assign(:page_title, "#{String.trim_trailing(group.name, "s")} Batteries")
     |> assign(:catalog_batteries, Catalog.all_for_usage(core_battery.config.usage, group.type))
     |> assign_system_batteries(group)}
  end

  defp assign_system_batteries(socket, group) do
    system_batteries =
      group.type
      |> Batteries.list_system_batteries_for_group()
      |> Map.new(&{&1.type, &1})

    assign(socket, :system_batteries, system_batteries)
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={"/#{@group.type}"} />

    <.grid columns={%{sm: 1, md: 2, xl: 3}}>
      <.panel :for={battery <- @catalog_batteries} title={battery.name} id={battery.type}>
        <:menu>
          <%= if system_battery = Map.get(@system_batteries, battery.type) do %>
            <div class="flex items-center justify-between flex-1">
              <.badge
                minimal
                label="ACTIVE"
                class="bg-green-500 dark:bg-green-500 text-white dark:text-white"
              />

              <.button
                link={~p"/batteries/#{system_battery.group}/edit/#{system_battery.id}"}
                icon={:pencil}
              >
                Edit
              </.button>
            </div>
          <% else %>
            <.button link={~p"/batteries/#{battery.group}/new/#{battery.type}"} icon={:bolt}>
              Install
            </.button>
          <% end %>
        </:menu>

        <p class="text-sm">{battery.description}</p>
      </.panel>
    </.grid>
    """
  end
end
