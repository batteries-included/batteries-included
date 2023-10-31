defmodule ControlServerWeb.Live.PostgresClusters do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.PostgresClusterTable

  alias CommonCore.Postgres.Cluster
  alias ControlServer.Postgres

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(current_page: :datastores)
     |> assign_clusters(list_clusters())
     |> assign_page_title("Postgres Clusters")}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def assign_clusters(socket, clusters) do
    assign(socket, clusters: clusters)
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  @spec list_clusters() :: list(Cluster.t())
  defp list_clusters do
    Postgres.list_clusters()
  end

  defp new_url, do: ~p"/postgres/new"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_button={%{link_type: "live_redirect", to: "/data"}} />
    <.panel>
      <:title>
        All Clusters
      </:title>
      <:top_right>
        <PC.button to={new_url()} link_type="live_redirect" label="New Cluster" />
      </:top_right>

      <.postgres_clusters_table rows={@clusters} />
    </.panel>
    """
  end
end
