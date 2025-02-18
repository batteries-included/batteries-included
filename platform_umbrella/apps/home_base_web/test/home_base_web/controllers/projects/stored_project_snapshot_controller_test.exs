defmodule HomeBaseWeb.StoredProjectSnapshotControllerTest do
  use HomeBaseWeb.ConnCase

  import HomeBase.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), installation: insert(:installation)}
  end

  defp sign(jwk, data) do
    jwk |> JOSE.JWT.sign(JOSE.JWT.from(data)) |> elem(1)
  end

  describe "stored project snapshot api" do
    test "can create a snapshot", %{conn: conn, installation: install} do
      snapshot_args = params_for(:project)

      conn =
        post(conn, ~p"/api/v1/installations/#{install.id}/project_snapshots",
          jwt: sign(install.control_jwk, snapshot_args)
        )

      assert %{"id" => _id} = json_response(conn, 201)["data"]
    end
  end
end
