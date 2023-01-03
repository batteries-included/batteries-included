defmodule ControlServerWeb.GroupBatteriesLive do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias KubeExt.Defaults.Catalog
  alias ControlServer.Batteries.Installer
  alias ControlServer.Batteries
  alias Phoenix.Naming
  alias EventCenter.Database, as: DatabaseEventCenter
  alias ControlServerWeb.Components.LeftMenu

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = DatabaseEventCenter.subscribe(:system_battery)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply,
     socket
     |> assign_catalog_batteries(socket.assigns.live_action)
     |> assign_system_batteries(socket.assigns.live_action)}
  end

  defp assign_catalog_batteries(socket, group) do
    assign(socket, :catalog_batteries, Catalog.all(group))
  end

  defp assign_system_batteries(socket, group) do
    map =
      group
      |> Batteries.list_system_batteries_for_group()
      |> Enum.map(&{&1.type, &1})
      |> Map.new()

    assign(socket, :system_batteries, map)
  end

  @impl Phoenix.LiveView
  def handle_event("start", %{"type" => type} = _params, socket) do
    Installer.install(type)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(_, socket) do
    send_update(LeftMenu, id: "left", group: socket.assigns.live_action, active: :batteries)
    {:noreply, assign_system_batteries(socket, socket.assigns.live_action)}
  end

  defp action_title(%{live_action: :ml} = assigns) do
    ~H"""
    <.title>Machine Learning Batteries</.title>
    """
  end

  defp action_title(%{live_action: :net_sec} = assigns) do
    ~H"""
    <.title>Network/Security Batteries</.title>
    """
  end

  defp action_title(assigns) do
    assigns =
      assign_new(assigns, :string_title, fn ->
        assigns
        |> Map.get(:live_action, "")
        |> Atom.to_string()
        |> String.capitalize()
      end)

    ~H"""
    <.title><%= @string_title %> Batteries</.title>
    """
  end

  defp active_check(assigns) do
    ~H"""
    <div class="flex text-shamrock-700 font-semi-bold">
      <div class="flex-initial">
        Active
      </div>
      <div class="flex-none ml-2">
        <Heroicons.check_circle class="h-6 w-6" />
      </div>
    </div>
    """
  end

  attr :battery, :any, required: true

  def start_button(assigns) do
    ~H"""
    <.button phx-click={:start} phx-value-type={@battery.type}>
      Install Battery
    </.button>
    """
  end

  defp is_active(active, type), do: Map.has_key?(active, type)

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={@live_action} active={:batteries}>
      <:title>
        <.action_title live_action={@live_action} />
      </:title>
      <.table id="batteries-table" rows={@catalog_batteries}>
        <:col :let={battery} label="Type">
          <%= Naming.humanize(battery.type) %>
        </:col>
        <:col :let={battery} label="Group">
          <%= battery.group %>
        </:col>
        <:col :let={battery} label="Status">
          <.active_check :if={is_active(@system_batteries, battery.type)} />
        </:col>
        <:action :let={battery}>
          <.start_button :if={!is_active(@system_batteries, battery.type)} battery={battery} />
        </:action>
      </.table>
    </.layout>
    """
  end
end
