defmodule ControlServerWeb.SystemBatteryLive.Show do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  alias ControlServer.Batteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:system_battery, Batteries.get_system_battery!(id))}
  end

  defp page_title(:show), do: "Show System battery"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout>
      <.data_list>
        <:item title="Id"><%= @system_battery.id %></:item>
        <:item title="Group"><%= @system_battery.group %></:item>
        <:item title="Type"><%= @system_battery.type %></:item>
      </.data_list>
    </.layout>
    """
  end
end
