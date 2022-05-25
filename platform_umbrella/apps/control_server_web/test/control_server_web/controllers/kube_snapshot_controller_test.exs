defmodule ControlServerWeb.KubeSnapshotControllerTest do
  use ControlServerWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all kube_snapshots", %{conn: conn} do
      conn = get(conn, Routes.kube_snapshot_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end
end
