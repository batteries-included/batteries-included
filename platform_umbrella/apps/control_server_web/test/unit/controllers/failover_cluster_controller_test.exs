defmodule ControlServerWeb.FailoverClusterControllerTest do
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias CommonCore.Redis.FailoverCluster

  @invalid_attrs %{
    name: nil,
    num_redis_instances: nil,
    num_sentinel_instances: nil,
    type: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all failover_clusters", %{conn: conn} do
      conn = get(conn, ~p"/api/redis/clusters")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create failover_cluster" do
    test "renders failover_cluster when data is valid", %{conn: conn} do
      attrs = params_for(:redis_cluster, name: "some name")
      conn = post(conn, ~p"/api/redis/clusters", failover_cluster: attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/redis/clusters/#{id}")

      assert %{
               "id" => ^id,
               "cpu_requested" => _,
               "memory_limits" => _,
               "memory_requested" => _,
               "name" => "some name",
               "num_redis_instances" => _,
               "num_sentinel_instances" => _,
               "type" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/redis/clusters", failover_cluster: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update failover_cluster" do
    setup [:create_failover_cluster]

    test "renders failover_cluster when data is valid", %{
      conn: conn,
      failover_cluster: %FailoverCluster{id: id} = failover_cluster
    } do
      update_attrs = params_for(:redis_cluster, name: "some updated name")
      conn = put(conn, ~p"/api/redis/clusters/#{failover_cluster}", failover_cluster: update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/redis/clusters/#{id}")

      assert %{
               "id" => ^id,
               "cpu_requested" => _,
               "memory_limits" => _,
               "memory_requested" => _,
               "name" => "some updated name",
               "num_redis_instances" => _,
               "num_sentinel_instances" => _,
               "type" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, failover_cluster: failover_cluster} do
      conn = put(conn, ~p"/api/redis/clusters/#{failover_cluster}", failover_cluster: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete failover_cluster" do
    setup [:create_failover_cluster]

    test "deletes chosen failover_cluster", %{conn: conn, failover_cluster: failover_cluster} do
      conn = delete(conn, ~p"/api/redis/clusters/#{failover_cluster}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/redis/clusters/#{failover_cluster}")
      end
    end
  end

  defp create_failover_cluster(_) do
    failover_cluster = insert(:redis_cluster)
    %{failover_cluster: failover_cluster}
  end
end
