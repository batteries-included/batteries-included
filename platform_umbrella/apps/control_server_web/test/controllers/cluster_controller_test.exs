defmodule ControlServerWeb.ClusterControllerTest do
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias CommonCore.Postgres.Cluster

  @invalid_attrs %{
    name: nil,
    num_instances: nil,
    type: nil,
    storage_size: nil,
    cpu_requested: nil,
    cpu_limits: nil,
    memory_limits: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all clusters", %{conn: conn} do
      conn = get(conn, ~p"/api/postgres/clusters")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create cluster" do
    test "renders cluster when data is valid", %{conn: conn} do
      attrs = params_for(:postgres_cluster, name: "some-name", type: :standard, virtual_size: "tiny")
      conn = post(conn, ~p"/api/postgres/clusters", cluster: attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/postgres/clusters/#{id}")

      assert %{
               "id" => ^id,
               "cpu_limits" => _,
               "cpu_requested" => _,
               "memory_limits" => _,
               "name" => "some-name",
               "num_instances" => _,
               "storage_size" => _,
               "type" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/postgres/clusters", cluster: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update cluster" do
    setup [:create_cluster]

    test "renders cluster when data is valid", %{conn: conn, cluster: %Cluster{id: id} = cluster} do
      update_attrs = params_for(:postgres_cluster, name: cluster.name, type: cluster.type)
      conn = put(conn, ~p"/api/postgres/clusters/#{cluster}", cluster: update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/postgres/clusters/#{id}")
      resp = json_response(conn, 200)["data"]

      name = cluster.name

      assert %{
               "id" => ^id,
               "cpu_limits" => _,
               "cpu_requested" => _,
               "memory_limits" => _,
               "name" => ^name,
               "num_instances" => _,
               "storage_size" => _,
               "type" => _
             } = resp
    end

    test "renders errors when data is invalid", %{conn: conn, cluster: %Cluster{id: id} = cluster} do
      update_attrs = params_for(:postgres_cluster, name: cluster.name, type: cluster.type)
      conn = put(conn, ~p"/api/postgres/clusters/#{cluster}", cluster: update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = put(conn, ~p"/api/postgres/clusters/#{cluster}", cluster: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete cluster" do
    setup [:create_cluster]

    test "deletes chosen cluster", %{conn: conn, cluster: cluster} do
      conn = delete(conn, ~p"/api/postgres/clusters/#{cluster}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/postgres/clusters/#{cluster}")
      end
    end
  end

  defp create_cluster(_) do
    cluster = insert(:postgres_cluster, type: :standard)
    %{cluster: cluster}
  end
end
