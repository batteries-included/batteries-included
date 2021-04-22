defmodule ControlServerWeb.RawConfigLiveTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest

  import ControlServer.Factory

  @update_attrs %{path: "some/updated/path"}
  @invalid_attrs %{path: nil}

  describe "Index" do
    test "lists all raw_configs", %{conn: conn} do
      raw_config = insert(:raw_config)
      {:ok, _index_live, html} = live(conn, Routes.raw_config_index_path(conn, :index))

      assert html =~ "Listing Raw configs"
      assert html =~ raw_config.path
    end

    test "saves new raw_config", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.raw_config_index_path(conn, :index))

      assert index_live |> element("a", "New Raw config") |> render_click() =~
               "New Raw config"

      assert_patch(index_live, Routes.raw_config_index_path(conn, :new))

      assert index_live
             |> form("#raw_config-form", raw_config: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#raw_config-form", raw_config: params_with_assocs(:raw_config))
        |> render_submit()
        |> follow_redirect(conn, Routes.raw_config_index_path(conn, :index))

      assert html =~ "Raw config created successfully"
      assert html =~ "/config/path-"
    end

    test "updates raw_config in listing", %{conn: conn} do
      raw_config = insert(:raw_config)
      {:ok, index_live, _html} = live(conn, Routes.raw_config_index_path(conn, :index))

      assert index_live |> element("#raw_config-#{raw_config.id} a", "Edit") |> render_click() =~
               "Edit Raw config"

      assert_patch(index_live, Routes.raw_config_index_path(conn, :edit, raw_config))

      assert index_live
             |> form("#raw_config-form", raw_config: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#raw_config-form", raw_config: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.raw_config_index_path(conn, :index))

      assert html =~ "Raw config updated successfully"
      assert html =~ "some/updated/path"
    end

    test "deletes raw_config in listing", %{conn: conn} do
      raw_config = insert(:raw_config)
      {:ok, index_live, _html} = live(conn, Routes.raw_config_index_path(conn, :index))

      assert index_live |> element("#raw_config-#{raw_config.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#raw_config-#{raw_config.id}")
    end
  end

  describe "Show" do
    test "displays raw_config", %{conn: conn} do
      raw_config = insert(:raw_config)
      {:ok, _show_live, html} = live(conn, Routes.raw_config_show_path(conn, :show, raw_config))

      assert html =~ "Show Raw config"
      assert html =~ raw_config.path
    end

    test "updates raw_config within modal", %{conn: conn} do
      raw_config = insert(:raw_config)
      {:ok, show_live, _html} = live(conn, Routes.raw_config_show_path(conn, :show, raw_config))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Raw config"

      assert_patch(show_live, Routes.raw_config_show_path(conn, :edit, raw_config))

      assert show_live
             |> form("#raw_config-form", raw_config: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#raw_config-form", raw_config: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.raw_config_show_path(conn, :show, raw_config))

      assert html =~ "Raw config updated successfully"
      assert html =~ "some/updated/path"
    end
  end
end
