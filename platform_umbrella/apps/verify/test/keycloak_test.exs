defmodule Verify.KeycloakTest do
  use Verify.TestCase,
    async: false,
    batteries: [keycloak: %{admin_username: "batteryadmin", admin_password: "password"}],
    images: ~w(keycloak)a

  setup_all do
    {:ok, session} = start_session()

    check_keycloak_running(session)

    Wallaby.end_session(session)
  end

  verify "can access keycloak console", %{session: session, requested_batteries: batteries} do
    %{admin_username: username, admin_password: password} = Keyword.fetch!(batteries, :keycloak)

    session
    |> navigate_to_keycloak_realm("Keycloak")
    |> click(Query.link("Admin Console"))
    |> last_tab()
    |> login_keycloak(username, password)
    |> assert_has(Query.css("#kc-main-content-page-container"))
  end
end
