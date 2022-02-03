defmodule ControlServerWeb.ServicesLive.DevtoolsHome do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view
  use Timex

  import ControlServerWeb.Layout
  import ControlServerWeb.PodDisplay

  alias ControlServer.Services
  alias ControlServer.Services.Pods

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok, socket |> assign(:pods, get_pods()) |> assign(:running, Services.Devtools.active?())}
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
    Services.Devtools.activate!()
    {:noreply, assign(socket, :running, true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Devtools</.title>
      </:title>
        <%= if @running do %>
          <div class="mt-4">
            <.pods_display pods={@pods} />
          </div>
        <% else %>
        <div class="mt-4 row">
          <.button phx-click="start_service">
            Install
          </.button>
        </div>
        <%end%>
      </.layout>
    """
  end
end
