defmodule ControlServerWeb.Live.MonitoringHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import KubeServices.SystemState.SummaryHosts

  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_batteries(socket)}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: SummaryBatteries.installed_batteries())
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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Monitoring">
      <:right_side>
        <PC.button
          label="Manage Batteries"
          color="light"
          to={~p"/batteries/monitoring"}
          link_type="live_redirect"
        />
      </:right_side>
    </.page_header>

    <.flex class="flex-col items-stretch justify-start">
      <.battery_link_panel :for={battery <- @batteries} battery={battery} />
    </.flex>
    """
  end
end
