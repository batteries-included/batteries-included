defmodule ControlServerWeb.CephFilesystemLiveTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import ControlServer.Factory

  defp create_ceph_filesystem(_) do
    %{ceph_filesystem: insert(:ceph_filesystem)}
  end

  describe "Show" do
    setup [:create_ceph_filesystem]

    test "displays ceph_filesystem", %{conn: conn, ceph_filesystem: ceph_filesystem} do
      {:ok, _show_live, html} =
        live(conn, Routes.ceph_filesystem_show_path(conn, :show, ceph_filesystem))

      assert html =~ "Show Ceph Filesystem"
      assert html =~ ceph_filesystem.name
    end
  end

  describe "Edit" do
    setup [:create_ceph_filesystem]

    @invalid_attrs %{
      name: nil,
      include_erasure_encoded: true
    }

    @update_attrs %{
      name: "newfilesystemtest",
      include_erasure_encoded: true
    }

    test "Can display an edit page for a filesystem", %{conn: conn, ceph_filesystem: fs} do
      {:ok, _show_live, html} = live(conn, Routes.ceph_filesystem_edit_path(conn, :edit, fs))

      assert html =~ fs.name
    end

    test "updates a filessystem", %{conn: conn, ceph_filesystem: ceph_filesystem} do
      {:ok, edit_live, _html} =
        live(conn, Routes.ceph_filesystem_edit_path(conn, :edit, ceph_filesystem))

      assert edit_live
             |> form("#ceph_filesystem-form", ceph_filesystem: @invalid_attrs)
             |> render_change() =~ "input-error"

      edit_live
      |> form("#ceph_filesystem-form", ceph_filesystem: @update_attrs)
      |> render_submit()

      {:ok, _, html} = live(conn, Routes.ceph_filesystem_show_path(conn, :show, ceph_filesystem))

      assert html =~ "newfilesystemtest"
    end
  end
end
