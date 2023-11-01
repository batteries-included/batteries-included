defmodule ControlServerWeb.Live.NetSecHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.IPAddressPoolsTable
  import ControlServerWeb.Keycloak.RealmsTable
  import KubeServices.SystemState.SummaryBatteries
  import KubeServices.SystemState.SummaryHosts
  import KubeServices.SystemState.SummaryRecent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_batteries() |> assign_keycloak_realms() |> assign_keycloak_url() |> assign_ip_address_pools()}
  end

  defp assign_batteries(socket) do
    assign(socket, batteries: installed_batteries())
  end

  defp assign_keycloak_realms(socket) do
    assign(socket, keycloak_realms: keycloak_realms())
  end

  defp assign_keycloak_url(socket) do
    assign(socket, :keycloak_url, "http://" <> keycloak_host())
  end

  defp assign_ip_address_pools(socket) do
    assign(socket, :ip_address_pools, ip_address_pools())
  end

  defp sso_panel(assigns) do
    ~H"""
    <.panel title="Realms">
      <:top_right>
        <.flex>
          <.a navigate={~p"/keycloak/realms"}>View All</.a>
        </.flex>
      </:top_right>
      <.keycloak_realms_table rows={@realms} keycloak_url={@keycloak_url} abbridged />
    </.panel>
    """
  end

  defp metallb_panel(assigns) do
    ~H"""
    <.panel title="MetalLB IPs">
      <:top_right>
        <.flex>
          <.a navigate={~p"/ip_address_pools"}>View All</.a>
        </.flex>
      </:top_right>
      <.ip_address_pools_table rows={@ip_address_pools} abbridged />
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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Net/Security">
      <:right_side>
        <PC.button
          label="Manage Batteries"
          color="light"
          to={~p"/batteries/net_sec"}
          link_type="live_redirect"
        />
      </:right_side>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <%= for battery <- @batteries do %>
        <%= case battery.type do %>
          <% :sso -> %>
            <.sso_panel realms={@keycloak_realms} keycloak_url={@keycloak_url} />
          <% :metallb -> %>
            <.metallb_panel ip_address_pools={@ip_address_pools} />
          <% _ -> %>
        <% end %>
      <% end %>
      <.flex class="flex-col items-stretch justify-start">
        <.battery_link_panel :for={battery <- @batteries} battery={battery} />
      </.flex>
    </.grid>
    """
  end
end
