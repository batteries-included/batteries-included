defmodule ControlServerWeb.Live.KeycloakRealmsList do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Keycloak.RealmsTable

  alias EventCenter.KeycloakSnapshot, as: SnapshotEventCenter
  alias KubeServices.Keycloak.AdminClient
  alias KubeServices.SystemState.SummaryURLs

  @impl Phoenix.LiveView
  def mount(%{} = _params, _session, socket) do
    if connected?(socket) do
      :ok = SnapshotEventCenter.subscribe()
    end

    {:ok,
     socket
     |> assign(:current_page, :net_sec)
     |> assign(:keycloak_url, SummaryURLs.url_for_battery(:keycloak))
     |> assign_realms()}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign_realms(socket)}
  end

  def assign_realms(socket) do
    case AdminClient.realms() do
      {:ok, realms} -> assign(socket, :realms, realms)
      _ -> assign(socket, :realms, [])
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
