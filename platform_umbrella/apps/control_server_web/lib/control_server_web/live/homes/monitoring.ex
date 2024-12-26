defmodule ControlServerWeb.Live.MonitoringHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.EmptyHome
  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Batteries.Catalog
  alias EventCenter.SystemStateSummary, as: SystemStateSummaryEventCenter
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = SystemStateSummaryEventCenter.subscribe()
    end

    {:ok,
     socket
     |> assign_batteries()
     |> assign_catalog_group()
     |> assign_current_page()
     |> assign_page_title()}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign_batteries(socket)}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: SummaryBatteries.installed_batteries(:monitoring))
  end

  defp assign_catalog_group(socket) do
    assign(socket, catalog_group: Catalog.group(:monitoring))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: socket.assigns.catalog_group.type)
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: socket.assigns.catalog_group.name)
  end

  defp battery_link_panel(%{battery: %{type: :grafana}} = assigns) do
    ~H"""
    <.a href={"//#{grafana_host()}/"} variant="bordered">Grafana</.a>
    """
  end

  defp battery_link_panel(%{battery: %{type: :vm_agent}} = assigns) do
    ~H"""
    <.a href={"//#{vmagent_host()}/"} variant="bordered">VM Agent</.a>
    """
  end

  defp battery_link_panel(%{battery: %{type: :victoria_metrics}} = assigns) do
    ~H"""
    <.a href={"//#{vmselect_host()}/select/0/vmui"} variant="bordered">VM Select</.a>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp install_path, do: ~p"/batteries/monitoring"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title}>
      <.button variant="secondary" icon={:kubernetes} link={install_path()}>
        Manage Batteries
      </.button>
    </.page_header>

    <.grid :if={@batteries && @batteries != []}>
      <.battery_link_panel :for={battery <- @batteries} battery={battery} />
    </.grid>

    <.empty_home :if={@batteries == []} icon={@catalog_group.icon} install_path={install_path()} />
    """
  end
end
