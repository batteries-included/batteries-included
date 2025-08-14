defmodule ControlServerWeb.Live.NetSecHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.EmptyHome
  import ControlServerWeb.Gateway.RoutesTable
  import ControlServerWeb.IPAddressPoolsTable
  import ControlServerWeb.Keycloak.RealmsTable
  import ControlServerWeb.Trivy.TrivyListTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryGateway
  import KubeServices.SystemState.SummaryHosts
  import KubeServices.SystemState.SummaryRecent
  import KubeServices.SystemState.SummaryURLs

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
     |> assign_keycloak_realms()
     |> assign_keycloak_url()
     |> assign_ip_address_pools()
     |> assign_gateway_routes()
     |> assign_vulnerability_reports()
     |> assign_catalog_group()
     |> assign_current_page()
     |> assign_page_title()}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply,
     socket
     |> assign_batteries()
     |> assign_keycloak_realms()
     |> assign_keycloak_url()
     |> assign_ip_address_pools()
     |> assign_gateway_routes()
     |> assign_vulnerability_reports()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries(:net_sec))
  end

  defp assign_keycloak_realms(socket) do
    assign(socket, keycloak_realms: keycloak_realms())
  end

  defp assign_vulnerability_reports(socket) do
    assign(socket, vulnerability_reports: aqua_vulnerability_reports())
  end

  defp assign_keycloak_url(socket) do
    assign(socket, :keycloak_url, url_for_battery(:keycloak))
  end

  defp assign_ip_address_pools(socket) do
    assign(socket, :ip_address_pools, ip_address_pools())
  end

  defp assign_gateway_routes(socket) do
    assign(socket, :routes, routes())
  end

  defp assign_catalog_group(socket) do
    assign(socket, catalog_group: Catalog.group(:net_sec))
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, socket.assigns.catalog_group.type)
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: socket.assigns.catalog_group.name)
  end

  defp keycloak_panel(assigns) do
    ~H"""
    <.panel title="Realms">
      <:menu>
        <.flex>
          <.button variant="minimal" link={~p"/keycloak/realms"}>View All</.button>
        </.flex>
      </:menu>
      <.keycloak_realms_table rows={@realms} keycloak_url={@keycloak_url} abridged />
    </.panel>
    """
  end

  defp metallb_panel(assigns) do
    ~H"""
    <.panel title="MetalLB IPs">
      <:menu>
        <.flex>
          <.button icon={:plus} link={~p"/ip_address_pools/new"}>New IP Address Pool</.button>
          <.button variant="minimal" link={~p"/ip_address_pools"}>View All</.button>
        </.flex>
      </:menu>
      <.ip_address_pools_table rows={@ip_address_pools} abridged />
    </.panel>
    """
  end

  defp trivy_panel(assigns) do
    ~H"""
    <.panel title="Trivy Security Reports">
      <:menu>
        <.flex>
          <.button variant="minimal" link={~p"/trivy_reports/vulnerability_report"}>View All</.button>
        </.flex>
      </:menu>
      <.trivy_list_table
        id="vulnerability-reports"
        type="vulnerability_report"
        reports={@vulnerability_reports}
        columns={[:name, :namespace, :critical, :high, :medium, :low, :actions]}
      />
    </.panel>
    """
  end

  defp routes_panel(assigns) do
    ~H"""
    <.panel :if={@routes != []} title="Routes">
      <:menu>
        <.flex>
          <.button variant="minimal" link={~p"/gateway/routes"}>View All</.button>
        </.flex>
      </:menu>
      <.routes_table abridged rows={@routes} />
    </.panel>
    """
  end

  defp battery_link_panel(%{battery: %{type: :kiali}} = assigns) do
    ~H"""
    <.panel>
      <.a href={"//#{kiali_host()}/"} variant="external">Kiali</.a>
    </.panel>
    """
  end

  defp battery_link_panel(assigns), do: ~H||

  defp install_path, do: ~p"/batteries/net_sec"

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
          <% :keycloak -> %>
            <.keycloak_panel realms={@keycloak_realms} keycloak_url={@keycloak_url} />
          <% :metallb -> %>
            <.metallb_panel ip_address_pools={@ip_address_pools} />
          <% :trivy_operator -> %>
            <.trivy_panel vulnerability_reports={@vulnerability_reports} />
          <% :gateway_api -> %>
            <.routes_panel routes={@routes} />
          <% _ -> %>
        <% end %>
      <% end %>

      <.flex column class="items-stretch justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>

    <.empty_home :if={@batteries == []} icon={@catalog_group.icon} install_path={install_path()} />
    """
  end
end
