defmodule ControlServerWeb.CephClusterLiveTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import ControlServer.Factory

  defp create_ceph_cluster(_) do
    %{ceph_cluster: insert(:ceph_cluster)}
  end

  describe "Show" do
    setup [:create_ceph_cluster]

    test "displays ceph_cluster", %{conn: conn, ceph_cluster: ceph_cluster} do
      {:ok, _show_live, html} =
        live(conn, Routes.ceph_cluster_show_path(conn, :show, ceph_cluster))

      assert html =~ "Show Ceph cluster"
      assert html =~ ceph_cluster.data_dir_host_path
    end
  end
end
