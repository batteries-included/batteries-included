defmodule ControlServerWeb.SystemBatteryLive.Index do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  alias ControlServer.Batteries

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :system_batteries, list_system_batteries())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing System batteries")
    |> assign(:system_battery, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    system_battery = Batteries.get_system_battery!(id)
    {:ok, _} = Batteries.delete_system_battery(system_battery)

    {:noreply, assign(socket, :system_batteries, list_system_batteries())}
  end

  defp list_system_batteries do
    Batteries.list_system_batteries()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <.table
        id="system_batteries"
        rows={@system_batteries}
        row_click={&JS.navigate("/system_batteries/#{&1.id}")}
      >
        <:col :let={system_battery} label="Id"><%= system_battery.id %></:col>
        <:col :let={system_battery} label="Group"><%= system_battery.group %></:col>
        <:col :let={system_battery} label="Type"><%= system_battery.type %></:col>
        <:action :let={system_battery}>
          <.link navigate={"/system_batteries/#{system_battery.id}"} type="styled">
            Show
          </.link>
        </:action>
        <:action :let={system_battery}>
          <.link
            phx-click={JS.push("delete", value: %{id: system_battery.id})}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </.layout>
    """
  end
end
