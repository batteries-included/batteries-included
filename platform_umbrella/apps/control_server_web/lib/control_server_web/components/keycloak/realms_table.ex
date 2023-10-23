defmodule ControlServerWeb.Keycloak.RealmsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :realms, :list, required: true
  attr :keycloak_url, :string, required: true

  def keycloak_realms_table(%{} = assigns) do
    ~H"""
    <PC.table id="keycloak-realms-table">
      <PC.tr>
        <PC.th>ID</PC.th>
        <PC.th>Name</PC.th>
        <PC.th class="w-10"></PC.th>
      </PC.tr>
      <%= for realm <- @realms do %>
        <PC.tr>
          <PC.td>
            <%= realm.id %>
          </PC.td>
          <PC.td><%= realm.displayName %></PC.td>
          <PC.td>
            <.a href={admin_url(@keycloak_url, realm)} variant="external">Keycloak Admin</.a>

            <.a navigate={~p"/keycloak/realm/#{realm.realm}"}>
              Show Realm
            </.a>
          </PC.td>
        </PC.tr>
      <% end %>
    </PC.table>
    """
  end

  defp admin_url(keycloak_url, realm) do
    Enum.join([keycloak_url, "admin", realm.realm, "console"], "/")
  end
end
