defmodule ControlServerWeb.Live.KeycloakRealmsList do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Keycloak.RealmsTable

  alias CommonCore.Keycloak.AdminClient
  alias KubeServices.SystemState.SummaryURLs

  @impl Phoenix.LiveView
  def mount(%{} = _params, _session, socket) do
    {:ok, socket |> assign_realms() |> assign_keycloak_url() |> assign_current_page()}
  end

  defp assign_realms(socket) do
    {:ok, realms} = AdminClient.realms()
    assign(socket, :realms, realms)
  end

  defp assign_keycloak_url(socket) do
    assign(socket, :keycloak_url, SummaryURLs.url_for_battery(:keycloak))
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :net_sec)
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.page_header title="Keycloak" back_link={~p"/net_sec"} />
    <.panel>
      <.keycloak_realms_table rows={@realms} keycloak_url={@keycloak_url} />
    </.panel>
    """
  end
end
