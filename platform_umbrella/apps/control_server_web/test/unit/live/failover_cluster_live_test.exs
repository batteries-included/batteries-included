defmodule ControlServerWeb.FailoverClusterLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.RedisFixtures
  import Phoenix.LiveViewTest

  defp create_failover_cluster(_) do
    failover_cluster = failover_cluster_fixture()
    %{failover_cluster: failover_cluster}
  end

  describe "Index" do
    setup [:create_failover_cluster]

    test "lists all failover_clusters", %{conn: conn, failover_cluster: failover_cluster} do
      {:ok, _index_live, html} = live(conn, ~p"/redis")

      assert html =~ "Redis Clusters"
      assert html =~ failover_cluster.name
    end

    test "links to new cluster form", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/redis")

      index_live
      |> element("a", "New Cluster")
      |> render_click()
      |> follow_redirect(conn, ~p"/redis/new")
    end
  end
end
