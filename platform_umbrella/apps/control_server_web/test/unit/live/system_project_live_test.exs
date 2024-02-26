defmodule ControlServerWeb.SystemProjectLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.ProjectsFixtures
  import Phoenix.LiveViewTest

  defp create_system_project(_) do
    system_project = system_project_fixture()
    %{system_project: system_project}
  end

  describe "Index" do
    setup [:create_system_project]

    @tag :slow
    test "lists all system_projects", %{conn: conn, system_project: system_project} do
      {:ok, _index_live, html} = live(conn, ~p"/system_projects")

      assert html =~ "projects"
      assert html =~ system_project.description
    end
  end

  describe "Show" do
    setup [:create_system_project]

    @tag :slow
    test "displays system_project", %{conn: conn, system_project: system_project} do
      {:ok, _show_live, html} = live(conn, ~p"/system_projects/#{system_project}")

      assert html =~ "Project"
    end
  end
end
