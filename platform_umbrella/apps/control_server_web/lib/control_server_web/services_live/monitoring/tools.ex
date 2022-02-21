defmodule ControlServerWeb.ServicesLive.MonitoringTools do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.PodDisplay

  alias ControlServer.Services.Pods

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Monitoring Tools</.title>
      </:title>
      <:left_menu>
        <.left_menu_item
          to="/services/monitoring/tools"
          name="Tools"
          icon="external_link"
          is_active={true}
        />
        <.left_menu_item
          to="/services/monitoring/settings"
          name="Service Settings"
          icon="lightning_bolt"
        />
        <.left_menu_item to="/services/monitoring/status" name="Status" icon="status_online" />
      </:left_menu>
      <.body_section>
        <.h4>Grafana</.h4>
        <.button link_type="live_redirect" to="/services/monitoring/grafana" variant="shadow">
          Open Grafana
          <Heroicons.Solid.external_link class={"w-5 h-5"} />
        </.button>
      </.body_section>
      <.body_section>
        <.h4>Prometheus</.h4>
        <.button link_type="live_redirect" to="/services/monitoring/prometheus" variant="shadow">
          Open Prometheus
          <Heroicons.Solid.external_link class={"w-5 h-5"} />
        </.button>
      </.body_section>
      <.body_section>
        <.button link_type="live_redirect" to="/services/monitoring/alert_manager" variant="shadow">
          Open Alert Manger
          <Heroicons.Solid.external_link class={"w-5 h-5"} />
        </.button>
      </.body_section>
    </.layout>
    """
  end
end
