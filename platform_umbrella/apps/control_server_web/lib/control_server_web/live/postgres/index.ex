defmodule ControlServerWeb.Live.PostgresIndex do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.PostgresClusterTable

  alias ControlServer.Postgres

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :data)
     |> assign(:page_title, "Postgres Clusters")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {clusters, meta}} <- Postgres.list_clusters(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:clusters, clusters)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/postgres?#{params}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/data"}>
      <.button variant="dark" icon={:plus} link={new_url()}>
        New Postgres Cluster
      </.button>
    </.page_header>

    <.panel title="All Clusters">
      <:menu>
        <.table_search
          meta={@meta}
          fields={[name: [op: :ilike]]}
          placeholder="Filter by name"
          on_change="search"
        />
      </:menu>

      <.postgres_clusters_table rows={@clusters} meta={@meta} />
    </.panel>
    """
  end

  defp new_url, do: ~p"/postgres/new"
end
