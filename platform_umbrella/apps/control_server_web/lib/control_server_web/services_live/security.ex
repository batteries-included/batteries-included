defmodule ControlServerWeb.ServicesLive.Security do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view
  use Timex

  import ControlServerWeb.Layout

  alias ControlServer.Services
  alias ControlServer.Services.Pods
  alias ControlServerWeb.RunnableServiceList

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok,
     socket
     |> assign(:pods, get_pods())
     |> assign(:services, [Services.CertManager])}
  end

  defp get_pods do
    Enum.map(Pods.get(), &Pods.summarize/1)
  end

  @impl true
  @spec handle_info(:update, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(:update, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

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
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>
          Security
        </.title>
      </:title>
      <div class="container-xxl">
        <div class="mt-4 row">
          <.live_component
            module={RunnableServiceList}
            services={@services}
            id={"security_base_services"}
          />
        </div>
        <div class="mt-2 row">
          <ControlServerWeb.PodDisplay.pods_display pods={@pods} />
        </div>
      </div>
    </.layout>
    """
  end
end
