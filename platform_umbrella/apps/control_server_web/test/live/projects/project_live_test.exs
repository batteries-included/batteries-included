defmodule ControlServerWeb.ProjectLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.ProjectsFixtures
  import Phoenix.LiveViewTest

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

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
      Installer.install!(:battery_core)
      Summarizer.new()
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
      {:ok, _view, html} = live(conn, ~p"/projects/#{project}/show")

      assert html =~ project.name
    end
  end

  describe "/projects/:id/edit" do
    @tag :slow
    test "should edit a project", %{conn: conn, project: project} do
      {:ok, view, _} = live(conn, ~p"/projects/#{project}/edit")

      {:ok, _, html} =
        view
        |> element("#edit-project-form")
        |> render_submit(%{project: %{name: "New Name", description: "New Description"}})
        |> follow_redirect(conn, ~p"/projects/#{project}/show")

      assert html =~ "New Name"
      assert html =~ "New Description"
    end
  end
end
