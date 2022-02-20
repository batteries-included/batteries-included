defmodule ControlServerWeb.ServicesLive.DevtoolsHome do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view
  use Timex

  import ControlServerWeb.Layout
  import ControlServerWeb.PodDisplay

  alias ControlServer.Services.Pods
  alias ControlServer.Services.RunnableService
  alias ControlServerWeb.RunnableServiceList

  require Logger

  @pod_update_time 5000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, @pod_update_time)

    {:ok,
     socket
     |> assign(:pods, get_pods())
     |> assign(:services, services())}
  end

  defp get_pods do
    Enum.map(Pods.get(), &Pods.summarize/1)
  end

  defp services do
    Enum.filter(RunnableService.services(), fn s -> String.starts_with?(s.path, "/devtools") end)
  end

  @impl true
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
        <.title>Devtools</.title>
      </:title>
      <div class="container-xxl">
        <div class="mt-4 row">
          <.live_component
            module={RunnableServiceList}
            services={@services}
            id={"devtools_base_services"}
          />
        </div>
        <div class="mt-2 row">
          <.pods_display pods={@pods} />
        </div>
      </div>
    </.layout>
    """
  end
end
