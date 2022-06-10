defmodule ControlServerWeb.ResourcePathControllerTest do
  use ControlServerWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all resource_paths", %{conn: conn} do
      conn = get(conn, Routes.resource_path_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end
end
