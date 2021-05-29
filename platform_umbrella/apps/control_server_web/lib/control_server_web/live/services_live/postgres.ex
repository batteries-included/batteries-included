defmodule ControlServerWeb.ServicesLive.Postgres do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view
  use Timex

  alias ControlServer.KubeServices
  alias ControlServer.Services
  alias ControlServer.Services.Pods

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok, socket |> assign(:pods, get_pods()) |> assign(:running, Services.Database.active?())}
  end

  defp get_pods do
    :postgres |> Pods.get() |> Enum.map(&Pods.summarize/1)
  end

  @impl true
  @spec handle_info(:update, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
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
    {:ok, _service} = Services.Database.activate()
    KubeServices.start_apply()

    {:noreply, assign(socket, :running, true)}
  end
end
