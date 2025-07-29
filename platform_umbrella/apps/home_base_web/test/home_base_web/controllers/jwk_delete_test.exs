defmodule HomeBaseWeb.JwkDeleteTest do
  use HomeBaseWeb.ConnCase

  import HomeBase.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), installation: insert(:installation)}
  end

  defp sign(jwk, data) do
    jwk |> JOSE.JWT.sign(JOSE.JWT.from(data)) |> elem(1)
  end

  describe "Host reports remove private key" do
    test "removes private key when creating stored host report", %{conn: conn, installation: install} do
      report = params_for(:host_report)

      install_one = HomeBase.CustomerInstalls.get_installation!(install.id)

      assert CommonCore.JWK.has_private_key?(install_one.control_jwk) == true,
             "Private key should exist before report is created"

      conn = post(conn, ~p"/api/v1/installations/#{install.id}/host_reports", jwt: sign(install.control_jwk, report))
      assert %{"id" => id} = json_response(conn, 201)["data"]

      report = HomeBase.ET.get_stored_host_report!(id)
      assert report

      install_two = HomeBase.CustomerInstalls.get_installation!(install.id)

      assert CommonCore.JWK.has_private_key?(install_two.control_jwk) == false,
             "Private key should not exist after report is created"
    end
  end

  describe "Usage reports remove the private keys" do
    test "removes private key when creating stored usage report", %{conn: conn, installation: install} do
      report = params_for(:usage_report)

      install_one = HomeBase.CustomerInstalls.get_installation!(install.id)

      assert CommonCore.JWK.has_private_key?(install_one.control_jwk) == true,
             "Private key should exist before report is created"

      conn = post(conn, ~p"/api/v1/installations/#{install.id}/usage_reports", jwt: sign(install.control_jwk, report))
      assert %{"id" => id} = json_response(conn, 201)["data"]

      report = HomeBase.ET.get_stored_usage_report!(id)
      assert report

      install_two = HomeBase.CustomerInstalls.get_installation!(install.id)

      assert CommonCore.JWK.has_private_key?(install_two.control_jwk) == false,
             "Private key should not exist after report is created"
    end
  end

  describe "Install spec  won't render without a private key" do
    test "renders errors when key is gone", %{conn: conn, installation: install} do
      # This assumes that the private key has been removed on usage report.
      report = params_for(:usage_report)
      conn = post(conn, ~p"/api/v1/installations/#{install.id}/usage_reports", jwt: sign(install.control_jwk, report))
      assert %{"id" => _} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/v1/installations/#{install.id}/spec")
      assert json_response(conn, 400)["errors"] != %{}
    end

    # This shows that there was some change from the test above
    test "Will render a spec before", %{conn: conn, installation: install} do
      conn = get(conn, ~p"/api/v1/installations/#{install.id}/spec")

      result = json_response(conn, 200)

      assert Map.has_key?(result, "jwt") == true
    end
  end
end
