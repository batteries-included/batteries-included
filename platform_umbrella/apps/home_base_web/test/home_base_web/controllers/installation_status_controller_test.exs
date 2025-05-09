defmodule HomeBaseWeb.InstallationStatusControllerTest do
  use HomeBaseWeb.ConnCase

  import HomeBase.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), installation: insert(:installation)}
  end

  describe "InstallationStatusController" do
    test "gets jwt on a new installation", %{conn: conn, installation: install} do
      conn = get(conn, ~p"/api/v1/installations/#{install.id}/status")
      assert json_response(conn, 200)["jwt"] != nil
    end

    test "can verify the jwt on status", %{conn: conn, installation: install} do
      conn = get(conn, ~p"/api/v1/installations/#{install.id}/status")
      jwt = json_response(conn, 200)["jwt"]

      assert {:ok, payload} = CommonCore.JWK.verify_from_home_base(jwt)
      assert payload["status"] == "ok"
    end
  end
end
