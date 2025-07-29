defmodule HomeBaseWeb.StableVersionControllerTest do
  use HomeBaseWeb.ConnCase

  describe "StableVersionController" do
    test "gets a jwt", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/stable_versions")
      assert json_response(conn, 200)["jwt"]
    end
  end
end
