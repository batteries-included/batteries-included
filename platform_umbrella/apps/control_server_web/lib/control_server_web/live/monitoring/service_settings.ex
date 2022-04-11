defmodule ControlServerWeb.Live.MonitoringServiceSettings do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Services.RunnableService
  alias ControlServer.Services
  alias ControlServerWeb.RunnableServiceList

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:runnable_services, runnable_services())
     |> assign(:base_services, base_services())}
  end

  defp runnable_services do
    Enum.filter(RunnableService.services(), fn s -> String.starts_with?(s.path, "/monitoring") end)
  end

  defp base_services do
    service_types = Enum.map(runnable_services(), fn rs -> rs.service_type end)

    Services.base_query()
    |> Services.with_service_type_in(service_types)
    |> Services.all()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Monitoring Settings</.title>
      </:title>
      <:left_menu>
        <.monitoring_menu active="settings" />
      </:left_menu>
      <.body_section>
        <.live_component
          module={RunnableServiceList}
          services={@services}
          id="monitoring_base_services"
        />
      </.body_section>
    </.layout>
    """
  end
end
