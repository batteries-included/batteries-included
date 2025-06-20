defmodule Verify.KeycloakTest do
  use Verify.TestCase,
    async: false,
    batteries: [keycloak: %{admin_username: "batteryadmin", admin_password: "password"}],
    images: ~w(keycloak)a

  @keycloak_realm_path "/keycloak/realms"

  setup_all do
    {:ok, session} = start_session()

    session
    |> assert_pods_in_sts_running("battery-core", "keycloak")
    |> visit(@keycloak_realm_path)
    # wait for the admin realm
    |> assert_has(table_row(minimum: 1))
    # wait for the default realm
    |> assert_has(table_row(minimum: 2))

    Wallaby.end_session(session)
  end

  verify "can access keycloak console", %{session: session, requested_batteries: batteries} do
    %{admin_username: username, admin_password: password} = Keyword.fetch!(batteries, :keycloak)

    session
    |> visit("/keycloak/realm/master")
    |> login_keycloak(username, password)
    |> assert_has(Query.css("#kc-main-content-page-container"))
  end
end
