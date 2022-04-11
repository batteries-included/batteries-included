defmodule ControlServerWeb.Live.MonitoringTools do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

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
        <.monitoring_menu active="tools" />
      </:left_menu>
      <.body_section>
        <.h4>Grafana</.h4>
        <.button to="//anton2:8081/x/grafana" variant="shadow" link_type="a">
          Open Grafana
          <Heroicons.Solid.external_link class="w-5 h-5" />
        </.button>
      </.body_section>
      <.body_section>
        <.h4>Prometheus</.h4>
        <.button to="//anton2:8081/x/prometheus" variant="shadow" link_type="a">
          Open Prometheus
          <Heroicons.Solid.external_link class="w-5 h-5" />
        </.button>
      </.body_section>
      <.body_section>
        <.button to="//anton2:8081/x/alert_manager" variant="shadow" link_type="a">
          Open Alert Manger
          <Heroicons.Solid.external_link class="w-5 h-5" />
        </.button>
      </.body_section>
    </.layout>
    """
  end
end
