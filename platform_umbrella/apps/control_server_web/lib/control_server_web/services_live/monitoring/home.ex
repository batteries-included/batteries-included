defmodule ControlServerWeb.ServicesLive.MonitoringHome do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout
  import ControlServerWeb.PodDisplay

  alias ControlServer.Services
  alias ControlServer.Services.Pods

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok, socket |> assign(:pods, get_pods()) |> assign(:running, running?())}
  end

  defp get_pods do
    Enum.map(Pods.get(), &Pods.summarize/1)
  end

  @impl true
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, @pod_update_time)
    {:noreply, assign(socket, :pods, get_pods())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
  end

  @impl true
  def handle_event("start_service", _, socket) do
    Services.PrometheusOperator.activate!()
    Services.Prometheus.activate!()
    Services.Grafana.activate!()
    Services.KubeMonitoring.activate!()

    {:noreply, assign(socket, :running, running?())}
  end

  defp running? do
    Services.PrometheusOperator.active?() && Services.Prometheus.active?() &&
      Services.Grafana.active?()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Monitoring</.title>
      </:title>
      <div class="container-xxl">
        <%= if @running do %>
          <div class="mt-4 row">
            <div class="col">
              <ul>
                <li>
                  <.link to={Routes.services_grafana_path(@socket, :index)}>
                    Grafana
                  </.link>
                </li>
                <li>
                  <.link to={Routes.services_prometheus_path(@socket, :index)}>
                    Prometheus
                  </.link>
                </li>
              </ul>
            </div>
          </div>
          <div class="mt-2 row">
            <div class="col">
              <.pods_display pods={@pods} />
            </div>
          </div>
        <% else %>
          <div class="mt-4 row">
            <div class="col align-self-center">
              The monitoring service is not currently enabled on this Batteries included
              cluster. To start installing please press the button.
            </div>
          </div>
          <div class="row">
            <div class="m-5 text-center col align-self-center">
              <.button phx-click="start_service">
                Install
              </.button>
            </div>
          </div>
        <% end %>
      </div>
    </.layout>
    """
  end
end
