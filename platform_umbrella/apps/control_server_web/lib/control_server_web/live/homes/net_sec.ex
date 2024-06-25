defmodule ControlServerWeb.Live.NetSecHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.EmptyHome
  import ControlServerWeb.IPAddressPoolsTable
  import ControlServerWeb.Istio.VirtualServicesTable
  import ControlServerWeb.Keycloak.RealmsTable
  import ControlServerWeb.VulnerabilityReportTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryHosts
  import KubeServices.SystemState.SummaryIstio
  import KubeServices.SystemState.SummaryRecent
  import KubeServices.SystemState.SummaryURLs

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_batteries()
     |> assign_keycloak_realms()
     |> assign_keycloak_url()
     |> assign_ip_address_pools()
     |> assign_istio_virtual_services()
     |> assign_vulnerability_reports()
     |> assign_current_page()}
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

  defp assign_istio_virtual_services(socket) do
    assign(socket, :virtual_services, virtual_services())
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :net_sec)
  end

  defp sso_panel(assigns) do
    ~H"""
    <.panel title="Realms">
      <:menu>
        <.flex>
          <.link navigate={~p"/keycloak/realms"}>View All</.link>
        </.flex>
      </:menu>
      <.keycloak_realms_table rows={@realms} keycloak_url={@keycloak_url} abbridged />
    </.panel>
    """
  end

  defp metallb_panel(assigns) do
    ~H"""
    <.panel title="MetalLB IPs">
      <:menu>
        <.flex>
          <.link navigate={~p"/ip_address_pools"}>View All</.link>
        </.flex>
      </:menu>
      <.ip_address_pools_table rows={@ip_address_pools} abbridged />
    </.panel>
    """
  end

  defp trivy_panel(assigns) do
    ~H"""
    <.panel title="Trivy Security Reports">
      <:menu>
        <.flex>
          <.link navigate={~p"/trivy_reports/vulnerability_report"}>View All</.link>
        </.flex>
      </:menu>
      <.vulnerability_reports_table reports={@vulnerability_reports} />
    </.panel>
    """
  end

  defp virtual_services_panel(assigns) do
    ~H"""
    <.panel :if={@virtual_services != []} title="Virtual Services">
      <:menu>
        <.flex>
          <.link navigate={~p"/istio/virtual_services"}>View All</.link>
        </.flex>
      </:menu>
      <.virtual_services_table abbridged rows={@virtual_services} />
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
    <.page_header title="Net/Security">
      <.button variant="secondary" icon={:kubernetes} link={install_path()}>
        Manage Batteries
      </.button>
    </.page_header>
    <.grid :if={@batteries && @batteries != []} columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :sso -> %>
            <.sso_panel realms={@keycloak_realms} keycloak_url={@keycloak_url} />
          <% :metallb -> %>
            <.metallb_panel ip_address_pools={@ip_address_pools} />
          <% :trivy_operator -> %>
            <.trivy_panel vulnerability_reports={@vulnerability_reports} />
          <% :istio -> %>
            <.virtual_services_panel virtual_services={@virtual_services} />
          <% _ -> %>
        <% end %>
      <% end %>

      <.flex column class="items-stretch justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>
    <.empty_home :if={@batteries == []} install_path={install_path()}>
      <:header>
        <.h2>Batteries Included Network & Security Tools</.h2>
      </:header>
    </.empty_home>
    """
  end
end
