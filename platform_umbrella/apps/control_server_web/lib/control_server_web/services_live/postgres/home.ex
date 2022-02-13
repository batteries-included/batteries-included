defmodule ControlServerWeb.ServicesLive.PostgresHome do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view
  use Timex

  import ControlServerWeb.Layout
  import ControlServerWeb.PostgresClusterDisplay
  import ControlServerWeb.PodDisplay

  alias ControlServer.Postgres
  alias ControlServer.Services
  alias ControlServer.Services.Pods

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok,
     socket
     |> assign(:pods, get_pods())
     |> assign(:running, Services.Database.active?())
     |> assign(:clusters, list_clusters())}
  end

  defp get_pods do
    Enum.map(Pods.get(), &Pods.summarize/1)
  end

  defp list_clusters do
    Postgres.list_clusters()
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
    Services.Database.activate!()

    {:noreply, assign(socket, :running, true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Databases</.title>
      </:title>
      <%= if @running do %>
        <div class="mt-4">
          <.pg_cluster_display clusters={@clusters} />
          <.pods_display pods={@pods} />
        </div>
      <% else %>
        <div class="mt-4 row">
          <div class="col align-self-center">
            The database service is not currently enabled on this Batteries included
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
    </.layout>
    """
  end
end
