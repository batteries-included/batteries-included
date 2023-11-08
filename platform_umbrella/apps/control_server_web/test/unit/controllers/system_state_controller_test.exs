defmodule ControlServerWeb.SystemStateControllerTest do
  use ControlServerWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "Shows a current state snapshot", %{conn: conn} do
      conn = get(conn, ~p"/api/system_state")
      assert %{} = json_response(conn, 200)["data"]
    end
  end
end
