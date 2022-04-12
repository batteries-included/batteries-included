defmodule ControlServerWeb.Live.DevtoolsServiceSettings do
  @moduledoc """
  Live web app for database stored json configs.
  """

  use ControlServerWeb, :live_view

  import ControlServerWeb.Apply
  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.RunnableServiceList

  alias ControlServer.Services.RunnableService
  alias ControlServer.Services

  require Logger

  @prefix "/devtools"

  @impl true
  def mount(_params, _session, socket) do
    EventCenter.BaseService.subscribe()

    {:ok, apply_services(socket, @prefix)}
  end

  @impl true
  def handle_info({_event_type, %Services.BaseService{} = _bs}, socket) do
    {:noreply, apply_services(socket, @prefix)}
  end

  @impl true
  def handle_event("start", %{"service-type" => service_type, "value" => _}, socket) do
    RunnableService.activate!(service_type)
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Devtools Settings</.title>
      </:title>
      <:left_menu>
        <.devtools_menu active="settings" base_services={@base_services} />
      </:left_menu>
      <.body_section>
        <.services_table runnable_services={@runnable_services} base_services={@base_services} />
      </.body_section>
    </.layout>
    """
  end
end
