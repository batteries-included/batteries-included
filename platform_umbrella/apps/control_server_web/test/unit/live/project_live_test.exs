defmodule ControlServerWeb.ProjectLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.ProjectsFixtures
  import Phoenix.LiveViewTest

  setup do
    %{project: project_fixture()}
  end

  describe "/projects" do
    @tag :slow
    test "should list all projects", %{conn: conn, project: project} do
      {:ok, _view, html} = live(conn, ~p"/projects")

      assert html =~ "All Projects"
      assert html =~ project.name
    end
  end

  describe "/projects/new" do
    @tag :slow
    test "should go through the new project flow", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/projects/new")

      assert view
             |> element("#project-form")
             |> render_change(project: %{type: :web}) =~ "Next Step"

      refute has_class?(view, "#project-form", "hidden")
      assert has_class?(view, "#project-web-form", "hidden")

      view
      |> element("#project-form")
      |> render_submit(project: %{name: "Foobar"})

      assert has_class?(view, "#project-form", "hidden")
      refute has_class?(view, "#project-web-form", "hidden")
    end
  end

  describe "/projects/:id" do
    @tag :slow
    test "should display a project", %{conn: conn, project: project} do
      {:ok, _view, html} = live(conn, ~p"/projects/#{project}")

      assert html =~ "Project Timeline"
      assert html =~ project.name
    end
  end
end
