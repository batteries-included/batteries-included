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
  alias EventCenter.SystemStateSummary, as: SystemStateSummaryEventCenter

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = SystemStateSummaryEventCenter.subscribe()
    end

    {:ok,
     socket
     |> assign_batteries()
     |> assign_redis_instances()
     |> assign_postgres_clusters()
     |> assign_ferret_services()
     |> assign_catalog_group()
     |> assign_current_page()
     |> assign_page_title()}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply,
     socket
     |> assign_batteries()
     |> assign_redis_instances()
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

  defp assign_redis_instances(socket) do
    assign(socket, redis_instances: redis_instances())
  end

  defp assign_ferret_services(socket) do
    assign(socket, ferret_services: ferret_services())
  end

  defp postgres_panel(assigns) do
    ~H"""
    <.panel title="Postgres">
      <:menu>
        <.flex>
          <.button icon={:plus} link={~p"/postgres/new"}>New PostgreSQL</.button>
          <.button variant="minimal" link={~p"/postgres"}>View All</.button>
        </.flex>
      </:menu>
      <.postgres_clusters_table rows={@clusters} abridged />
    </.panel>
    """
  end

  defp redis_panel(assigns) do
    ~H"""
    <.panel title="Redis">
      <:menu>
        <.flex>
          <.button icon={:plus} link={~p"/redis/new"}>New Redis</.button>
          <.button variant="minimal" link={~p"/redis"}>View All</.button>
        </.flex>
      </:menu>
      <.redis_table rows={@clusters} abridged />
    </.panel>
    """
  end

  defp ferretdb_panel(assigns) do
    ~H"""
    <.panel title="FerretDB/MongoDB">
      <:menu>
        <.flex>
          <.button icon={:plus} link={~p"/ferretdb/new"}>New FerretDB</.button>
          <.button variant="minimal" link={~p"/ferretdb"}>View All</.button>
        </.flex>
      </:menu>
      <.ferret_services_table rows={@ferret_services} abridged />
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
            <.redis_panel clusters={@redis_instances} />
          <% _ -> %>
        <% end %>
      <% end %>
    </.grid>

    <.empty_home :if={@batteries == []} icon={@catalog_group.icon} install_path={install_path()} />
    """
  end
end
