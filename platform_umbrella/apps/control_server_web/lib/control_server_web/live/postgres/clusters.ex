defmodule ControlServerWeb.Live.PostgresClusters do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.PostgresClusterDisplay

  alias ControlServer.Postgres

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :clusters, list_clusters())}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp list_clusters do
    Postgres.list_clusters()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Postgres Clusters</.title>
      </:title>
      <:left_menu>
        <.left_menu_item to="/services/data" name="Home" icon="home" />
        <.left_menu_item
          to="/services/data/clusters"
          name="Postgres Clusters"
          icon="database"
          is_active={true}
        />
        <.left_menu_item to="/services/data/settings" name="Service Settings" icon="lightning_bolt" />
        <.left_menu_item to="/services/data/status" name="Status" icon="status_online" />
      </:left_menu>
      <.body_section>
        <.pg_cluster_display clusters={@clusters} />
      </.body_section>
    </.layout>
    """
  end
end
