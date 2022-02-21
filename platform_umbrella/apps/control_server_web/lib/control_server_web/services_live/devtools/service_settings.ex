defmodule ControlServerWeb.ServicesLive.DevtoolsServiceSettings do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Services.RunnableService
  alias ControlServerWeb.RunnableServiceList

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :services, services())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp services do
    Enum.filter(RunnableService.services(), fn s -> String.starts_with?(s.path, "/devtools") end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Devtools Settings</.title>
      </:title>
      <:left_menu>
        <.left_menu_item
          to="/services/devtools/settings"
          name="Service Settings"
          icon="lightning_bolt"
          is_active={true}
        />
        <.left_menu_item to="/services/devtools/status" name="Status" icon="status_online" />
      </:left_menu>
      <.body_section>
        <.live_component
          module={RunnableServiceList}
          services={@services}
          id={"devtools_base_services"}
        />
      </.body_section>
    </.layout>
    """
  end
end
