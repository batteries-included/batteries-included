defmodule ControlServerWeb.Live.DataHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.EmptyHome
  import ControlServerWeb.FerretServicesTable
  import ControlServerWeb.PostgresClusterTable
  import ControlServerWeb.RedisTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryRecent

  alias CommonCore.Batteries.Catalog

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_catalog_group()
     |> assign_current_page()
     |> assign_page_title()
     |> assign_batteries()
     |> assign_redis_clusters()
     |> assign_postgres_clusters()
     |> assign_ferret_services()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries())
  end

  defp assign_catalog_group(socket) do
    assign(socket, catalog_group: Catalog.group(:data))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: socket.assigns.catalog_group.type)
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: socket.assigns.catalog_group.name)
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
          <.a navigate={~p"/postgres/new"}>
            <.icon name={:plus} class="inline-flex h-5 w-auto my-auto" /> New PostgreSQL
          </.a>
          <.link navigate={~p"/postgres"}>View All</.link>
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
          <.a navigate={~p"/redis/new"}>
            <.icon name={:plus} class="inline-flex h-5 w-auto my-auto" /> New Redis
          </.a>
          <.link navigate={~p"/redis"}>View All</.link>
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
          <.a navigate={~p"/ferretdb/new"}>
            <.icon name={:plus} class="inline-flex h-5 w-auto my-auto" /> New FerretDB
          </.a>
          <.link navigate={~p"/ferretdb"}>View All</.link>
        </.flex>
      </:menu>
      <.ferret_services_table rows={@ferret_services} abbridged />
    </.panel>
    """
  end

  defp install_path, do: ~p"/batteries/data"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title}>
      <.button variant="secondary" icon={:kubernetes} link={install_path()}>
        Manage Batteries
      </.button>
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

    <.empty_home :if={@batteries == []} icon={@catalog_group.icon} install_path={install_path()} />
    """
  end
end
