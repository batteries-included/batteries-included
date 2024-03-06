defmodule ControlServerWeb.Live.MonitoringHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.EmptyHome
  import KubeServices.SystemState.SummaryHosts

  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_batteries(socket)}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: SummaryBatteries.installed_batteries(:monitoring))
  end

  defp battery_link_panel(%{battery: %{type: :grafana}} = assigns) do
    ~H"""
    <.panel>
      <.a href={"//#{grafana_host()}/"} variant="external">Grafana</.a>
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :vm_agent}} = assigns) do
    ~H"""
    <.panel>
      <.a href={"//#{vmagent_host()}/"} variant="external">VM Agent</.a>
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :vm_cluster}} = assigns) do
    ~H"""
    <.panel>
      <.a href={"//#{vmselect_host()}/select/0/vmui"} variant="external">VM Select</.a>
    </.panel>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp install_path, do: ~p"/batteries/monitoring"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Monitoring">
      <:menu>
        <.button variant="secondary" link={install_path()}>
          Manage Batteries
        </.button>
      </:menu>
    </.page_header>

    <.flex :if={@batteries && @batteries != []} column class="items-stretch justify-start">
      <.battery_link_panel :for={battery <- @batteries} battery={battery} />
    </.flex>
    <.empty_home :if={@batteries == []} install_path={install_path()} />
    """
  end
end
