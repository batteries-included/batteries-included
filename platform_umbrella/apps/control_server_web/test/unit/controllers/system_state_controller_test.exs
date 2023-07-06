defmodule ControlServerWeb.SystemStateControllerTest do
  use ControlServerWeb.ConnCase

  @expected_empty %{
    "ceph_clusters" => [],
    "ceph_filesystems" => [],
    "ip_address_pools" => [],
    "knative_services" => [],
    "kube_state" => %{},
    "notebooks" => [],
    "postgres_clusters" => [],
    "redis_clusters" => [],
    "batteries" => [],
    "keycloak_state" => nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "Shows a current state snapshot", %{conn: conn} do
      conn = get(conn, ~p"/api/system_state")
      assert json_response(conn, 200)["data"] == @expected_empty
    end
  end
end
