defmodule ControlServerWeb.ServicesLive.Prometheus do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use Surface.LiveView
  use Timex

  alias CommonUI.Button
  alias ControlServer.Services
  alias ControlServer.Services.Pods
  alias ControlServerWeb.Live.Layout

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok, socket |> assign(:pods, get_pods()) |> assign(:running, Services.Monitoring.active?())}
  end

  defp get_pods do
    :monitoring |> Pods.get() |> Enum.map(&Pods.summarize/1)
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
    {:ok, _service} = Services.Monitoring.activate()

    {:noreply, assign(socket, :running, true)}
  end
end
