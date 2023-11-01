defmodule ControlServerWeb.Live.DataHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.PostgresClusterTable
  import ControlServerWeb.RedisTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryRecent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_batteries()
     |> assign_redis_clusters()
     |> assign_postgres_clusters()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries())
  end

  defp assign_postgres_clusters(socket) do
    assign(socket, postgres_clusters: postgres_clusters())
  end

  defp assign_redis_clusters(socket) do
    assign(socket, redis_clusters: redis_clusters())
  end

  defp postgres_panel(assigns) do
    ~H"""
    <.panel title="Postgres">
      <:top_right>
        <.flex>
          <.a navigate={~p"/postgres"}>View All</.a>
        </.flex>
      </:top_right>
      <.postgres_clusters_table rows={@clusters} abbridged />
    </.panel>
    """
  end

  defp redis_panel(assigns) do
    ~H"""
    <.panel title="Redis">
      <:top_right>
        <.flex>
          <.a navigate={~p"/redis"}>View All</.a>
        </.flex>
      </:top_right>
      <.redis_table rows={@clusters} abbridged />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Data Storage">
      <:right_side>
        <PC.button
          label="Manage Batteries"
          color="light"
          to={~p"/batteries/data"}
          link_type="live_redirect"
        />
      </:right_side>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :cloudnative_pg -> %>
            <.postgres_panel clusters={@postgres_clusters} />
          <% :redis -> %>
            <.redis_panel clusters={@redis_clusters} />
          <% _ -> %>
        <% end %>
      <% end %>
    </.grid>
    """
  end
end
