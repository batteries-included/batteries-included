defmodule ServerWeb.RawConfigControllerTest do
  use ServerWeb.ConnCase
  import Server.Factory

  @update_attrs %{
    content: %{},
    path: "some/updated/path"
  }
  @invalid_attrs %{content: nil, path: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all raw_configs", %{conn: conn} do
      cluster = insert(:kube_cluster)
      index_path = Routes.kube_cluster_raw_config_path(conn, :index, cluster.id)
      conn = get(conn, index_path)
      assert json_response(conn, 200)["data"] == []
    end

    test "lists no raw_configs with filter", %{conn: conn} do
      config = insert(:raw_config)
      index_path = Routes.kube_cluster_raw_config_path(conn, :index, config.kube_cluster_id)
      conn = get(conn, index_path, path: "not/our/path")
      assert json_response(conn, 200)["data"] == []
    end

    test "lists one raw_configs with good filter", %{conn: conn} do
      raw_config = insert(:raw_config)
      index_path = Routes.kube_cluster_raw_config_path(conn, :index, raw_config.kube_cluster_id)
      config_path = raw_config.path
      conn = get(conn, index_path, path: raw_config.path)

      assert [%{"content" => %{}, "id" => _id, "path" => ^config_path}] =
               json_response(conn, 200)["data"]
    end
  end

  describe "create raw_config" do
    test "renders raw_config when data is valid", %{conn: conn} do
      kube_cluster = insert(:kube_cluster)
      create_path = Routes.kube_cluster_raw_config_path(conn, :create, kube_cluster.id)
      conn = post(conn, create_path, raw_config: params_for(:raw_config))

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.kube_cluster_raw_config_path(conn, :show, kube_cluster.id, id))

      assert %{
               "id" => ^id,
               "content" => %{},
               "path" => _path
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      kube_cluster = insert(:kube_cluster)
      create_path = Routes.kube_cluster_raw_config_path(conn, :create, kube_cluster.id)
      conn = post(conn, create_path, raw_config: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update raw_config" do
    test "renders raw_config when data is valid", %{conn: conn} do
      raw_config = insert(:raw_config)
      id = raw_config.id

      update_path =
        Routes.kube_cluster_raw_config_path(conn, :update, raw_config.kube_cluster, raw_config)

      show_path =
        Routes.kube_cluster_raw_config_path(conn, :show, raw_config.kube_cluster, raw_config)

      conn = put(conn, update_path, raw_config: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]
      conn = get(conn, show_path)

      assert %{
               "id" => ^id,
               "content" => %{},
               "path" => "some/updated/path"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      raw_config = insert(:raw_config)
      update_path =
        Routes.kube_cluster_raw_config_path(conn, :update, raw_config.kube_cluster, raw_config)
      conn = put(conn, update_path, raw_config: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete raw_config" do
    test "deletes chosen raw_config", %{conn: conn} do
      raw_config = insert(:raw_config)

      delete_path =
        Routes.kube_cluster_raw_config_path(conn, :delete, raw_config.kube_cluster_id, raw_config)
      show_path =
        Routes.kube_cluster_raw_config_path(conn, :show, raw_config.kube_cluster_id, raw_config)

      conn = delete(conn, delete_path)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get(conn,show_path)
      end
    end
  end
end
