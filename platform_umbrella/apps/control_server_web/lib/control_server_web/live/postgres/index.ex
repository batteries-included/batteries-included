defmodule ControlServerWeb.Live.PostgresClusters do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServerWeb.PostgresClusterTable

  alias ControlServer.Postgres

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
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

  defp list_clusters do
    Postgres.list_clusters()
  end

  defp new_url, do: ~p"/postgres/new"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1><%= @page_title %></.h1>
    <.card>
      <.postgres_clusters_table rows={@clusters} />
    </.card>

    <.h2 variant="fancy">Actions</.h2>
    <.card>
      <div class="grid md:grid-cols-1 gap-6">
        <.a navigate={new_url()} class="block">
          <.button class="w-full">
            New Cluster
          </.button>
        </.a>
      </div>
    </.card>
    """
  end
end
