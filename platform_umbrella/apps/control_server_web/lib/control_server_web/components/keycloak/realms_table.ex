defmodule ControlServerWeb.Keycloak.RealmsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :rows, :list, required: true
  attr :keycloak_url, :string, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def keycloak_realms_table(%{} = assigns) do
    ~H"""
    <.table id="keycloak-realms-table" rows={@rows}>
      <:col :let={realm} :if={!@abbridged} label="ID"><%= realm.id %></:col>
      <:col :let={realm} label="Name"><%= realm.displayName %></:col>

      <:action :let={realm} :if={!@abbridged}>
        <.a href={admin_url(@keycloak_url, realm)} variant="external">Keycloak Admin</.a>
      </:action>

      <:action :let={realm}>
        <.a navigate={~p"/keycloak/realm/#{realm.realm}"}>
          Show
        </.a>
      </:action>
    </.table>
    """
  end

  defp admin_url(keycloak_url, realm) do
    Enum.join([keycloak_url, "admin", realm.realm, "console"], "/")
  end
end
