defmodule ControlServerWeb.ClusterLiveTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ControlServer.Postgres

  @create_attrs %{
    name: "some name",
    num_instances: 42,
    postgres_version: "some postgres_version",
    size: "some size"
  }
  @update_attrs %{
    name: "some updated name",
    num_instances: 43,
    postgres_version: "some updated postgres_version",
    size: "some updated size"
  }
  @invalid_attrs %{name: nil, num_instances: nil, postgres_version: nil, size: nil}

  defp fixture(:cluster) do
    {:ok, cluster} = Postgres.create_cluster(@create_attrs)
    cluster
  end

  defp create_cluster(_) do
    cluster = fixture(:cluster)
    %{cluster: cluster}
  end

  describe "Index" do
    setup [:create_cluster]

    test "lists all clusters", %{conn: conn, cluster: cluster} do
      {:ok, _index_live, html} = live(conn, Routes.cluster_index_path(conn, :index))

      assert html =~ "Listing Clusters"
      assert html =~ cluster.name
    end

    test "saves new cluster", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.cluster_index_path(conn, :index))

      assert index_live |> element("a", "New Cluster") |> render_click() =~
               "New Cluster"

      assert_patch(index_live, Routes.cluster_index_path(conn, :new))

      assert index_live
             |> form("#cluster-form", cluster: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#cluster-form", cluster: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.cluster_index_path(conn, :index))

      assert html =~ "Cluster created successfully"
      assert html =~ "some name"
    end

    test "updates cluster in listing", %{conn: conn, cluster: cluster} do
      {:ok, index_live, _html} = live(conn, Routes.cluster_index_path(conn, :index))

      assert index_live |> element("#cluster-#{cluster.id} a", "Edit") |> render_click() =~
               "Edit Cluster"

      assert_patch(index_live, Routes.cluster_index_path(conn, :edit, cluster))

      assert index_live
             |> form("#cluster-form", cluster: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#cluster-form", cluster: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.cluster_index_path(conn, :index))

      assert html =~ "Cluster updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes cluster in listing", %{conn: conn, cluster: cluster} do
      {:ok, index_live, _html} = live(conn, Routes.cluster_index_path(conn, :index))

      assert index_live |> element("#cluster-#{cluster.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#cluster-#{cluster.id}")
    end
  end

  describe "Show" do
    setup [:create_cluster]

    test "displays cluster", %{conn: conn, cluster: cluster} do
      {:ok, _show_live, html} = live(conn, Routes.cluster_show_path(conn, :show, cluster))

      assert html =~ "Show Cluster"
      assert html =~ cluster.name
    end

    test "updates cluster within modal", %{conn: conn, cluster: cluster} do
      {:ok, show_live, _html} = live(conn, Routes.cluster_show_path(conn, :show, cluster))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Cluster"

      assert_patch(show_live, Routes.cluster_show_path(conn, :edit, cluster))

      assert show_live
             |> form("#cluster-form", cluster: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#cluster-form", cluster: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.cluster_show_path(conn, :show, cluster))

      assert html =~ "Cluster updated successfully"
      assert html =~ "some updated name"
    end
  end
end
