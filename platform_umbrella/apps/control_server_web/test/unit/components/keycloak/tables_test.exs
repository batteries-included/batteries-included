defmodule ControlServerWeb.Keycloak.TablesTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.Keycloak.ClientsTable
  import ControlServerWeb.Keycloak.RealmsTable
  import ControlServerWeb.Keycloak.UsersTable

  @realm_one %{id: "00-00-00-00-00-00", displayName: "Keycloak", realm: "master"}
  @client_one %{
    clientId: "admin-cli",
    name: "Admin CLI",
    baseUrl: nil,
    enabled: true
  }
  describe "keycloak_realms_table/1" do
    component_snapshot_test "with master" do
      assigns = %{realms: [@realm_one]}

      ~H"""
      <.keycloak_realms_table
        rows={@realms}
        keycloak_url="http://keycloak.example.129-99-1-1.ip.batteriesincl.com"
      />
      """
    end
  end

  describe "keycloak_users_table/1" do
    component_snapshot_test "with a user" do
      assigns = %{
        users: [
          %{
            id: "00-00-00-00-00-00-00-00-00-00-01",
            username: "root",
            enabled: true,
            emailVerified: false,
            createdTimestamp: DateTime.utc_now() |> DateTime.add(-2, :day) |> DateTime.to_unix()
          }
        ]
      }

      ~H"""
      <.keycloak_users_table users={@users} hide_created />
      """
    end
  end

  describe "keycloak_clients_table/1" do
    component_snapshot_test "with a client" do
      assigns = %{clients: [@client_one]}

      ~H"""
      <.keycloak_clients_table clients={@clients} />
      """
    end
  end
end
