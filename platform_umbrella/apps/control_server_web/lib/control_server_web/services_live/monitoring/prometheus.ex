defmodule ControlServerWeb.ServicesLive.Prometheus do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :surface_view

  alias CommonUI.Button
  alias ControlServer.Services
  alias ControlServer.Services.Pods
  alias ControlServerWeb.Layout

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
    <div class="container-xxl">
    <h2 class="mt-2 text-2xl font-bold leading-7 text-pink-500 sm:text-3xl sm:truncate">
      Monitoring
    </h2>
    <hr class="mt-4">
    {#if @running}
      <div class="mt-4 row">
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
