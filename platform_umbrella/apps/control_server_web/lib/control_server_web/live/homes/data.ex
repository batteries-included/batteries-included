defmodule ControlServerWeb.Live.DataHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.EmptyHome
  import ControlServerWeb.FerretServicesTable
  import ControlServerWeb.PostgresClusterTable
  import ControlServerWeb.RedisTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryRecent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_page_title()
     |> assign_current_page()
     |> assign_batteries()
     |> assign_redis_clusters()
     |> assign_postgres_clusters()
     |> assign_ferret_services()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries())
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: "Data Storage")
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :data)
  end

  defp assign_postgres_clusters(socket) do
    assign(socket, postgres_clusters: postgres_clusters())
  end

  defp assign_redis_clusters(socket) do
    assign(socket, redis_clusters: redis_clusters())
  end

  defp assign_ferret_services(socket) do
    assign(socket, ferret_services: ferret_services())
  end

  defp postgres_panel(assigns) do
    ~H"""
    <.panel title="Postgres">
      <:menu>
        <.flex>
          <.a navigate={~p"/postgres/new"} variant="styled">
            <PC.icon name={:plus} class="inline-flex h-5 w-auto my-auto" /> New PostgreSQL
          </.a>
          <.a navigate={~p"/postgres"}>View All</.a>
        </.flex>
      </:menu>
      <.postgres_clusters_table rows={@clusters} abbridged />
    </.panel>
    """
  end

  defp redis_panel(assigns) do
    ~H"""
    <.panel title="Redis">
      <:menu>
        <.flex>
          <.a navigate={~p"/redis/new"} variant="styled">
            <PC.icon name={:plus} class="inline-flex h-5 w-auto my-auto" /> New Redis
          </.a>
          <.a navigate={~p"/redis"}>View All</.a>
        </.flex>
      </:menu>
      <.redis_table rows={@clusters} abbridged />
    </.panel>
    """
  end

  defp ferretdb_panel(assigns) do
    ~H"""
    <.panel title="FerretDB/MongoDB">
      <:menu>
        <.flex>
          <.a navigate={~p"/ferretdb/new"} variant="styled">
            <PC.icon name={:plus} class="inline-flex h-5 w-auto my-auto" /> New FerretDB
          </.a>
          <.a navigate={~p"/ferretdb"}>View All</.a>
        </.flex>
      </:menu>
      <.ferret_services_table
        rows={Enum.with_index(@ferret_services) |> Enum.map(fn {a, b} -> {b, a} end)}
        abbridged
      />
    </.panel>
    """
  end

  defp install_path, do: ~p"/batteries/data"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title}>
      <:menu>
        <PC.button
          label="Manage Batteries"
          color="light"
          to={install_path()}
          link_type="live_redirect"
        />
      </:menu>
    </.page_header>
    <.grid :if={@batteries && @batteries != []} columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :cloudnative_pg -> %>
            <.postgres_panel clusters={@postgres_clusters} />
          <% :ferretdb -> %>
            <.ferretdb_panel ferret_services={@ferret_services} />
          <% :redis -> %>
            <.redis_panel clusters={@redis_clusters} />
          <% _ -> %>
        <% end %>
      <% end %>
    </.grid>
    <.empty_home :if={@batteries == []} install_path={install_path()} />
    """
  end
end
