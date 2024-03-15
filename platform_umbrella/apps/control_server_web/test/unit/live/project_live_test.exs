defmodule ControlServerWeb.ProjectLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.ProjectsFixtures
  import Phoenix.LiveViewTest

  defp create_project(_) do
    project = project_fixture()
    %{project: project}
  end

  describe "Index" do
    setup [:create_project]

    @tag :slow
    test "lists all projects", %{conn: conn, project: project} do
      {:ok, _index_live, html} = live(conn, ~p"/projects")

      assert html =~ "projects"
      assert html =~ project.description
    end
  end

  describe "Show" do
    setup [:create_project]

    @tag :slow
    test "displays project", %{conn: conn, project: project} do
      {:ok, _show_live, html} = live(conn, ~p"/projects/#{project}")

      assert html =~ "Project"
    end
  end
end
