defmodule ControlServerWeb.RedisInstanceControllerTest do
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias CommonCore.Redis.RedisInstance

  @invalid_attrs %{
    name: nil,
    num_instances: nil,
    type: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all redis_instances", %{conn: conn} do
      conn = get(conn, ~p"/api/redis/clusters")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create redis_instance" do
    test "renders redis_instance when data is valid", %{conn: conn} do
      attrs = params_for(:redis_instance, name: "some-name", type: :standard)
      conn = post(conn, ~p"/api/redis/clusters", redis_instance: attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/redis/clusters/#{id}")

      assert %{
               "id" => ^id,
               "cpu_requested" => _,
               "memory_limits" => _,
               "memory_requested" => _,
               "name" => "some-name",
               "num_instances" => _,
               "type" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/redis/clusters", redis_instance: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update redis_instance" do
    setup [:create_redis_instance]

    test "renders redis_instance when data is valid", %{
      conn: conn,
      redis_instance: %RedisInstance{id: id} = redis_instance
    } do
      update_attrs = params_for(:redis_instance, name: redis_instance.name, type: redis_instance.type)
      conn = put(conn, ~p"/api/redis/clusters/#{redis_instance}", redis_instance: update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/redis/clusters/#{id}")

      assert %{
               "id" => ^id,
               "cpu_requested" => _,
               "memory_limits" => _,
               "memory_requested" => _,
               "num_instances" => _,
               "type" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, redis_instance: redis_instance} do
      conn = put(conn, ~p"/api/redis/clusters/#{redis_instance}", redis_instance: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete redis_instance" do
    setup [:create_redis_instance]

    test "deletes chosen redis_instance", %{conn: conn, redis_instance: redis_instance} do
      conn = delete(conn, ~p"/api/redis/clusters/#{redis_instance}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/redis/clusters/#{redis_instance}")
      end
    end
  end

  defp create_redis_instance(_) do
    redis_instance = insert(:redis_instance)
    %{redis_instance: redis_instance}
  end
end
