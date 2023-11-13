defmodule ControlServerWeb.Keycloak.RealmsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :rows, :list, required: true
  attr :keycloak_url, :string, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def keycloak_realms_table(%{} = assigns) do
    ~H"""
    <.table id="keycloak-realms-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={realm} :if={!@abbridged} label="ID"><%= realm.id %></:col>
      <:col :let={realm} label="Name"><%= realm.displayName %></:col>

      <:col :let={realm} :if={!@abbridged} label="Admin">
        <.a href={admin_url(@keycloak_url, realm)} variant="external">Keycloak Admin</.a>
      </:col>

      <:action :let={realm}>
        <.action_icon
          to={show_url(realm)}
          icon={:eye}
          tooltip={"Show realm " <> realm.displayName}
          id={"realm_show_link_" <> realm.id}
        />
      </:action>
    </.table>
    """
  end

  defp admin_url(keycloak_url, realm) do
    Enum.join([keycloak_url, "admin", realm.realm, "console"], "/")
  end

  defp show_url(realm) do
    ~p"/keycloak/realm/#{realm.realm}"
  end
end
