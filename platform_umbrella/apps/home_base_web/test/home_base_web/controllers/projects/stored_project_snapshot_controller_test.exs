defmodule HomeBaseWeb.StoredProjectSnapshotControllerTest do
  use HomeBaseWeb.ConnCase

  import HomeBase.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), installation: insert(:installation)}
  end

  defp encrypt(jwk, data) do
    CommonCore.JWK.encrypt(jwk, data)
  end

  describe "stored project snapshot api" do
    test "can create a snapshot", %{conn: conn, installation: install} do
      snapshot_args = params_for(:project)

      conn =
        post(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots",
          jwt: encrypt(install.control_jwk, snapshot_args)
        )

      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end
  end

  test "can get snapshots", %{conn: conn, installation: install} do
    snapshot_args = params_for(:project)

    conn =
      post(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots",
        jwt: encrypt(install.control_jwk, snapshot_args)
      )

    conn = get(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots")

    assert %{} = json_response(conn, 200)["data"]
  end
end
