defmodule ControlServerWeb.ServicesLive.MonitoringHome do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :surface_view

  alias CommonUI.Button
  alias CommonUI.Layout.Title
  alias ControlServer.Services
  alias ControlServer.Services.Pods
  alias ControlServerWeb.Layout
  alias Surface.Components.Link

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok, socket |> assign(:pods, get_pods()) |> assign(:running, Services.Monitoring.active?())}
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
    Services.Monitoring.activate!()

    {:noreply, assign(socket, :running, true)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout>
      <Title>Monitoring</Title>
      <div class="container-xxl">
        {#if @running}
          <div class="mt-4 row">
            <div class="col">
              <ul>
                <li>
                  <Link to={Routes.services_grafana_path(@socket, :index)}>
                    Grafana
                  </Link>
                </li>
                <li>
                  <Link to={Routes.services_prometheus_path(@socket, :index)}>
                    Prometheus
                  </Link>
                </li>
              </ul>
            </div>
          </div>
          <div class="mt-2 row">
            <div class="col">
              <ControlServerWeb.PodDisplay {=@pods} />
            </div>
          </div>
        {#else}
          <div class="mt-4 row">
            <div class="col align-self-center">
              The monitoring service is not currently enabled on this Batteries included
              cluster. To start installing please press the button.
            </div>
          </div>
          <div class="row">
            <div class="m-5 text-center col align-self-center">
              <Button click="start_service">
                Install
              </Button>
            </div>
          </div>
        {/if}
      </div>
    </Layout>
    """
  end
end
