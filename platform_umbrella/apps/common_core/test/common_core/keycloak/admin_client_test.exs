defmodule CommonCore.Keycloak.TestAdminClient do
  @moduledoc false
  use ExUnit.Case

  import Mox

  alias CommonCore.Keycloak.AdminClient
  alias CommonCore.Keycloak.TeslaMock

  @access_key_value "VALUE_KEY_HERE"
  @refresh_key_value "REFRESH_KEY_HERE"
  @default_token_response_body %{
    "access_token" => @access_key_value,
    "expires_in" => 30,
    "refresh_expires_in" => 90,
    "refresh_token" => @refresh_key_value
  }

  @full_url "http://keycloak.local.test/realms/master/protocol/openid-connect/token"
  @realms_url "http://keycloak.local.test/admin/realms"
  @battery_core_users_url "http://keycloak.local.test/admin/realms/batterycore/users"
  @battery_core_clients_url "http://keycloak.local.test/admin/realms/batterycore/clients"

  describe "login/1" do
    setup [:verify_on_exit!, :setup_mocked_admin]

    test "gets a new token with the username and password", %{pid: pid} do
      expect_openid_token(1)
      assert :ok = AdminClient.login(pid)
    end
  end

  describe "refresh/1" do
    setup [:verify_on_exit!, :setup_mocked_admin]

    test "will login then refresh", %{pid: pid} do
      expect_openid_token(2)
      assert :ok = AdminClient.refresh(pid)
    end

    test "will reuse the existing refresh token when asked to refresh", %{pid: pid} do
      # expect that
      # two new tokens are gotten this test implictly tests
      # that tokens are reused when they are still fine.
      expect_openid_token(2)
      assert :ok = AdminClient.login(pid)
      assert :ok = AdminClient.refresh(pid)
    end
  end

  describe "realms/1" do
    setup [:verify_on_exit!, :setup_mocked_admin]

    test "will return the realm list", %{pid: pid} do
      expect_openid_token(1)
      expect_realms()

      assert {:ok, []} = AdminClient.realms(pid)
    end
  end

  describe "create_user/1" do
    setup [:verify_on_exit!, :setup_mocked_admin]

    test "will return ok", %{pid: pid} do
      expect_openid_token(1)
      new_url = @battery_core_users_url <> "/33"

      expect(TeslaMock, :call, fn %{url: @battery_core_users_url}, _opts ->
        {:ok, %Tesla.Env{status: 201, headers: [{"location", new_url}]}}
      end)

      assert {:ok, ^new_url} =
               AdminClient.create_user(pid, "batterycore", %{
                 username: "elliott",
                 email: "elliott@batteriesincl.com",
                 enabled: true
               })
    end
  end

  describe "create_client/1" do
    setup [:verify_on_exit!, :setup_mocked_admin]

    test "will return ok", %{pid: pid} do
      expect_openid_token(1)
      new_url = @battery_core_clients_url <> "/33"

      expect(TeslaMock, :call, fn %{url: @battery_core_clients_url}, _opts ->
        {:ok, %Tesla.Env{status: 201, headers: [{"location", new_url}]}}
      end)

      assert {:ok, ^new_url} =
               AdminClient.create_client(pid, "batterycore", %{
                 name: "grafana-0",
                 rootUrl: "https://grafana.example.com",
                 enabled: true,
                 secret: "secret123"
               })
    end
  end

  defp build_random_byte_string(n) do
    n
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, n)
  end

  defp setup_mocked_admin(_context) do
    {:ok, pid} =
      AdminClient.start_link(
        adapter: CommonCore.Keycloak.TeslaMock,
        base_url: "http://keycloak.local.test/",
        username: "test_user",
        password: "not-real-test",
        name: String.to_atom("admin-client-test-#{build_random_byte_string(10)}")
      )

    allow(CommonCore.Keycloak.TeslaMock, self(), pid)

    %{pid: pid}
  end

  defp expect_openid_token(n_calls) do
    expect(TeslaMock, :call, n_calls, fn %{url: @full_url}, _opts ->
      {:ok, %Tesla.Env{status: 200, body: @default_token_response_body}}
    end)
  end

  defp expect_realms(return_value \\ []) do
    expect(TeslaMock, :call, fn %{url: @realms_url}, _opts ->
      {:ok, %Tesla.Env{status: 200, body: return_value}}
    end)
  end
end
