defmodule ControlServerWeb.ServicesLive.DatabaseHome do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Database Home</.title>
      </:title>
      <:left_menu>
        <.left_menu_item to="/services/database" name="Home" icon="home" is_active={true} />
        <.left_menu_item to="/services/database/clusters" name="Postgres Clusters" icon="database" />
        <.left_menu_item
          to="/services/database/settings"
          name="Service Settings"
          icon="lightning_bolt"
        />
        <.left_menu_item to="/services/database/status" name="Status" icon="status_online" />
      </:left_menu>
      <.body_section></.body_section>
    </.layout>
    """
  end
end
