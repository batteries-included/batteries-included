defmodule ControlServerWeb.FailoverClusterLiveTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import ControlServer.RedisFixtures

  defp create_failover_cluster(_) do
    failover_cluster = failover_cluster_fixture()
    %{failover_cluster: failover_cluster}
  end

  describe "Index" do
    setup [:create_failover_cluster]

    test "lists all failover_clusters", %{conn: conn, failover_cluster: failover_cluster} do
      {:ok, _index_live, html} = live(conn, Routes.redis_path(conn, :index))

      assert html =~ "Listing Failover clusters"
      assert html =~ failover_cluster.name
    end

    test "links to new cluster form", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.redis_path(conn, :index))

      index_live
      |> element("a", "New Cluster")
      |> render_click()
      |> follow_redirect(conn, Routes.redis_new_path(conn, :new))
    end
  end
end
