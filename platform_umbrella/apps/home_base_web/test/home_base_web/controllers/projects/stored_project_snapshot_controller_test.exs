defmodule HomeBaseWeb.StoredProjectSnapshotControllerTest do
  use HomeBaseWeb.ConnCase

  import HomeBase.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), installation: insert(:installation)}
  end

  describe "stored project snapshot api" do
    test "can create a snapshot", %{conn: conn, installation: install} do
      snapshot_args = params_for(:project)

      conn =
        post(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots",
          jwt: CommonCore.JWK.encrypt_to_home_base(install.control_jwk, snapshot_args)
        )

      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end
  end

  test "can get snapshots", %{conn: conn, installation: install} do
    snapshot_args = params_for(:project)

    conn =
      post(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots",
        jwt: CommonCore.JWK.encrypt_to_home_base(install.control_jwk, snapshot_args)
      )

    conn = get(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots")

    assert %{} = json_response(conn, 200)["jwt"]

    decoded_response = CommonCore.JWK.decrypt_from_home_base!(install.control_jwk, json_response(conn, 200)["jwt"])

    created_included =
      decoded_response
      |> Map.get("snapshots")
      |> Enum.any?(fn snapshot ->
        snapshot["name"] == snapshot_args.name
      end)

    assert created_included, "Created snapshot should be included in the response"
  end

  test "can get a single snapshot", %{conn: conn, installation: install} do
    snapshot_args = params_for(:project)

    conn =
      post(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots",
        jwt: CommonCore.JWK.encrypt_to_home_base(install.control_jwk, snapshot_args)
      )

    %{"id" => id} = json_response(conn, 201)["data"]

    conn = get(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots/#{id}")

    assert %{} = json_response(conn, 200)["jwt"]
  end
end
