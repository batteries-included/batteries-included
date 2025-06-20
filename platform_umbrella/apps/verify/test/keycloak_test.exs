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
    config = Keyword.fetch!(batteries, :keycloak)

    session =
      session
      |> visit("/keycloak/realm/master")
      |> assert_has(h3("Keycloak"))
      |> click(Query.link("Admin Console"))

    session
    |> window_handles()
    |> List.last()
    |> then(&focus_window(session, &1))
    |> assert_has(Query.css("div.kc-logo-text"))
    |> fill_in(Query.text_field("username"), with: config.admin_username)
    |> fill_in(Query.text_field("password"), with: config.admin_password)
    |> click(Query.button("Sign In"))
  end
end
