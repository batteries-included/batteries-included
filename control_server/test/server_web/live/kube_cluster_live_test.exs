defmodule ServerWeb.KubeClusterLiveTest do
  use ServerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Server.Clusters

  @create_attrs %{adopted: true, external_uid: "some external_uid"}
  @update_attrs %{adopted: false, external_uid: "some updated external_uid"}
  @invalid_attrs %{external_uid: nil}

  defp fixture(:kube_cluster) do
    {:ok, kube_cluster} = Clusters.create_kube_cluster(@create_attrs)
    kube_cluster
  end

  defp create_kube_cluster(_) do
    kube_cluster = fixture(:kube_cluster)
    %{kube_cluster: kube_cluster}
  end

  describe "Index" do
    setup [:create_kube_cluster]

    test "lists all kube_clusters", %{conn: conn, kube_cluster: kube_cluster} do
      {:ok, _index_live, html} = live(conn, Routes.kube_cluster_index_path(conn, :index))

      assert html =~ "Listing Kube clusters"
      assert html =~ kube_cluster.external_uid
    end

    test "saves new kube_cluster", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.kube_cluster_index_path(conn, :index))

      assert index_live |> element("a", "New Kube cluster") |> render_click() =~
               "New Kube cluster"

      assert_patch(index_live, Routes.kube_cluster_index_path(conn, :new))

      assert index_live
             |> form("#kube_cluster-form", kube_cluster: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#kube_cluster-form", kube_cluster: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.kube_cluster_index_path(conn, :index))

      assert html =~ "Kube cluster created successfully"
      assert html =~ "some external_uid"
    end

    test "updates kube_cluster in listing", %{conn: conn, kube_cluster: kube_cluster} do
      {:ok, index_live, _html} = live(conn, Routes.kube_cluster_index_path(conn, :index))

      assert index_live |> element("#kube_cluster-#{kube_cluster.id} a", "Edit") |> render_click() =~
               "Edit Kube cluster"

      assert_patch(index_live, Routes.kube_cluster_index_path(conn, :edit, kube_cluster))

      assert index_live
             |> form("#kube_cluster-form", kube_cluster: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#kube_cluster-form", kube_cluster: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.kube_cluster_index_path(conn, :index))

      assert html =~ "Kube cluster updated successfully"
      assert html =~ "some updated external_uid"
    end

    test "deletes kube_cluster in listing", %{conn: conn, kube_cluster: kube_cluster} do
      {:ok, index_live, _html} = live(conn, Routes.kube_cluster_index_path(conn, :index))

      assert index_live
             |> element("#kube_cluster-#{kube_cluster.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#kube_cluster-#{kube_cluster.id}")
    end
  end

  describe "Show" do
    setup [:create_kube_cluster]

    test "displays kube_cluster", %{conn: conn, kube_cluster: kube_cluster} do
      {:ok, _show_live, html} =
        live(conn, Routes.kube_cluster_show_path(conn, :show, kube_cluster))

      assert html =~ "Show Kube cluster"
      assert html =~ kube_cluster.external_uid
    end

    test "updates kube_cluster within modal", %{conn: conn, kube_cluster: kube_cluster} do
      {:ok, show_live, _html} =
        live(conn, Routes.kube_cluster_show_path(conn, :show, kube_cluster))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Kube cluster"

      assert_patch(show_live, Routes.kube_cluster_show_path(conn, :edit, kube_cluster))

      assert show_live
             |> form("#kube_cluster-form", kube_cluster: @invalid_attrs)
             |> render_change() =~ "can&apos;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#kube_cluster-form", kube_cluster: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.kube_cluster_show_path(conn, :show, kube_cluster))

      assert html =~ "Kube cluster updated successfully"
      assert html =~ "some updated external_uid"
    end
  end
end
