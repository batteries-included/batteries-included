defmodule ServerWeb.KubeClusterControllerTest do
  use ServerWeb.ConnCase

  alias Server.Clusters
  alias Server.Clusters.KubeCluster

  @create_attrs %{
    adopted: false,
    external_uid: "some external_uid"
  }
  @update_attrs %{
    adopted: true,
    external_uid: "some updated external_uid"
  }
  @invalid_attrs %{adopted: nil, external_uid: nil}

  def fixture(:kube_cluster) do
    {:ok, kube_cluster} = Clusters.create_kube_cluster(@create_attrs)
    kube_cluster
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all kube_clusters", %{conn: conn} do
      conn = get(conn, Routes.kube_cluster_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create kube_cluster" do
    test "renders kube_cluster when data is valid", %{conn: conn} do
      conn = post(conn, Routes.kube_cluster_path(conn, :create), kube_cluster: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.kube_cluster_path(conn, :show, id))

      assert %{
               "id" => id,
               "adopted" => false,
               "external_uid" => "some external_uid"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.kube_cluster_path(conn, :create), kube_cluster: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update kube_cluster" do
    setup [:create_kube_cluster]

    test "renders kube_cluster when data is valid", %{
      conn: conn,
      kube_cluster: %KubeCluster{id: id} = kube_cluster
    } do
      conn =
        put(conn, Routes.kube_cluster_path(conn, :update, kube_cluster),
          kube_cluster: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.kube_cluster_path(conn, :show, id))

      assert %{
               "id" => id,
               "adopted" => false,
               "external_uid" => "some updated external_uid"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, kube_cluster: kube_cluster} do
      conn =
        put(conn, Routes.kube_cluster_path(conn, :update, kube_cluster),
          kube_cluster: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete kube_cluster" do
    setup [:create_kube_cluster]

    test "deletes chosen kube_cluster", %{conn: conn, kube_cluster: kube_cluster} do
      conn = delete(conn, Routes.kube_cluster_path(conn, :delete, kube_cluster))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.kube_cluster_path(conn, :show, kube_cluster))
      end
    end
  end

  defp create_kube_cluster(_) do
    kube_cluster = fixture(:kube_cluster)
    %{kube_cluster: kube_cluster}
  end
end
