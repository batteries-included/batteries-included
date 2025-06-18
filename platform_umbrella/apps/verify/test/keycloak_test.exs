defmodule Verify.KeycloakTest do
  use Verify.TestCase, async: false, batteries: ~w(keycloak)a, images: ~w(keycloak)a

  @keycloak_realm_path "/keycloak/realms"

  setup_all do
    {:ok, session} = start_session()

    session
    |> sleep(5_000)
    |> assert_pods_in_sts_running("battery-core", "keycloak")
    |> sleep(5_000)
    |> assert_pods_in_sts_running("battery-core", "keycloak")
    |> visit(@keycloak_realm_path)
    |> sleep(15_000)
    # wait for the admin realm
    |> assert_has(table_row(minimum: 1))
    # wait for the default realm
    |> assert_has(table_row(minimum: 2))

    Wallaby.end_session(session)
  end

  verify "can access keycloak", %{session: session} do
    session
    |> visit(@keycloak_realm_path)
    |> find(table_row(at: 0), &click(&1, Query.link("Keycloak Admin")))
    |> sleep(5_000)
  end
end
