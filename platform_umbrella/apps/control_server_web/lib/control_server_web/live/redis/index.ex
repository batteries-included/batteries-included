defmodule ControlServerWeb.Live.RedisIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.RedisTable

  alias ControlServer.Redis

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :data)
     |> assign(:page_title, "Redis Clusters")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {failover_clusters, meta}} <- Redis.list_failover_clusters(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:failover_clusters, failover_clusters)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/redis?#{params}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/data"}>
      <.button variant="dark" icon={:plus} link={new_url()}>
        New Redis Cluster
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

      <.redis_table rows={@failover_clusters} meta={@meta} />
    </.panel>
    """
  end

  def new_url, do: ~p"/redis/new"
end
