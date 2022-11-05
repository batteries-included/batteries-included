defmodule ControlServerWeb.SystemProjectLiveTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import ControlServer.ProjectsFixtures

  @create_attrs %{description: "some description", name: "some name", type: :web}
  @update_attrs %{description: "some updated description", name: "some updated name", type: :ml}
  @invalid_attrs %{description: nil, name: nil, type: nil}

  defp create_system_project(_) do
    system_project = system_project_fixture()
    %{system_project: system_project}
  end

  describe "Index" do
    setup [:create_system_project]

    test "lists all system_projects", %{conn: conn, system_project: system_project} do
      {:ok, _index_live, html} = live(conn, ~p"/system_projects")

      assert html =~ "Listing System projects"
      assert html =~ system_project.description
    end

    test "saves new system_project", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/system_projects")

      assert index_live |> element("a", "New System project") |> render_click() =~
               "New System project"

      assert_patch(index_live, ~p"/system_projects/new")

      assert index_live
             |> form("#system_project-form", system_project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#system_project-form", system_project: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/system_projects")

      assert html =~ "System project created successfully"
      assert html =~ "some description"
    end

    test "updates system_project in listing", %{conn: conn, system_project: system_project} do
      {:ok, index_live, _html} = live(conn, ~p"/system_projects")

      assert index_live
             |> element("#system_projects-#{system_project.id} a", "Edit")
             |> render_click() =~
               "Edit System project"

      assert_patch(index_live, ~p"/system_projects/#{system_project}/edit")

      assert index_live
             |> form("#system_project-form", system_project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#system_project-form", system_project: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/system_projects")

      assert html =~ "System project updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes system_project in listing", %{conn: conn, system_project: system_project} do
      {:ok, index_live, _html} = live(conn, ~p"/system_projects")

      assert index_live
             |> element("#system_projects-#{system_project.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#system_project-#{system_project.id}")
    end
  end

  describe "Show" do
    setup [:create_system_project]

    test "displays system_project", %{conn: conn, system_project: system_project} do
      {:ok, _show_live, html} = live(conn, ~p"/system_projects/#{system_project}")

      assert html =~ "Show System project"
      assert html =~ system_project.description
    end

    test "updates system_project within modal", %{conn: conn, system_project: system_project} do
      {:ok, show_live, _html} = live(conn, ~p"/system_projects/#{system_project}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit System project"

      assert_patch(show_live, ~p"/system_projects/#{system_project}/show/edit")

      assert show_live
             |> form("#system_project-form", system_project: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#system_project-form", system_project: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/system_projects/#{system_project}")

      assert html =~ "System project updated successfully"
      assert html =~ "some updated description"
    end
  end
end
