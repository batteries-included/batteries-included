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
     |> assign(:page_title, "Redis Instances")}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {redis_instances, meta}} <- Redis.list_redis_instances(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:redis_instances, redis_instances)
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
        New Redis Instance
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

      <.redis_table rows={@redis_instances} meta={@meta} />
    </.panel>
    """
  end

  def new_url, do: ~p"/redis/new"
end
