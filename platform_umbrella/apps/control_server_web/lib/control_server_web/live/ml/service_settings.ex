defmodule ControlServerWeb.Live.MLServiceSettings do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.RunnableServiceList

  alias ControlServer.Services.RunnableService
  alias ControlServer.Services

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    EventCenter.BaseService.subscribe()

    {:ok,
     socket
     |> assign(:runnable_services, runnable_services())
     |> assign(:base_services, base_services())}
  end

  defp runnable_services, do: RunnableService.prefix("/ml")

  defp base_services do
    runnable_services()
    |> Enum.map(fn rs -> rs.service_type end)
    |> Services.from_service_types()
  end

  @impl true
  def handle_event("start", %{"service-type" => service_type, "value" => _}, socket) do
    RunnableService.activate!(service_type)
    {:noreply, socket}
  end

  @impl true
  def handle_info({_event_type, %Services.BaseService{} = _bs}, socket) do
    {:noreply, assign(socket, :base_services, base_services())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>ML Settings</.title>
      </:title>
      <:left_menu>
        <.ml_menu active="home" />
      </:left_menu>
      <.body_section>
        <.services_table runnable_services={@runnable_services} base_services={@base_services} />
      </.body_section>
    </.layout>
    """
  end
end
