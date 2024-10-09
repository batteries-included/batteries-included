defmodule ControlServerWeb.Live.KeycloakRealmsList do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Keycloak.RealmsTable

  alias KubeServices.Keycloak.AdminClient
  alias KubeServices.SystemState.SummaryURLs

  @impl Phoenix.LiveView
  def mount(%{} = _params, _session, socket) do
    socket
    |> assign(:current_page, :net_sec)
    |> assign(:keycloak_url, SummaryURLs.url_for_battery(:keycloak))
    |> assign_realms()
  end

  def assign_realms(socket) do
    case AdminClient.realms() do
      {:ok, realms} -> {:ok, assign(socket, :realms, realms)}
      _ -> {:ok, assign(socket, :realms, [])}
    end
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
