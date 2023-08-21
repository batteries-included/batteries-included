defmodule ControlServerWeb.Live.KeycloakRealmsList do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServerWeb.Keycloak.RealmsTable

  alias CommonCore.Keycloak.AdminClient
  alias KubeServices.SystemState.SummaryHosts

  @impl Phoenix.LiveView
  def mount(%{} = _params, _session, socket) do
    {:ok, socket |> assign_realms() |> assign_keycloak_url()}
  end

  defp assign_realms(socket) do
    {:ok, realms} = AdminClient.realms()
    assign(socket, :realms, realms)
  end

  defp assign_keycloak_url(socket) do
    assign(socket, :keycloak_url, "http://" <> SummaryHosts.keycloak_host())
  end

  @impl Phoenix.LiveView
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.h1>
      Keycloak
      <:sub_header>Realms</:sub_header>
    </.h1>
    <.keycloak_realms_table realms={@realms} keycloak_url={@keycloak_url} />
    """
  end
end
