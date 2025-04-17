defmodule Verify.ProjectCreationTest do
  use Verify.TestCase, async: false

  @moduletag :cluster_test

  test "can start a demo like project", %{session: session, control_url: url} do
    project_name = "pastebin-#{:rand.uniform(10_000)}"

    session
    |> visit(url)
    |> assert_has(Query.text("Home", minimum: 1))
    |> click(Query.link("New Project"))
    |> fill_in(Query.text_field("project[name]"), with: project_name)
    |> find(Query.select("Project Type"), fn select ->
      click(select, Query.option("Web"))
    end)
    |> click(Query.button("Next Step"))
    |> click(Query.text("I need a database"))
    |> touch_scroll(Query.text("Next Step"), 0, 0)
    |> click(Query.button("Next Step"))
    |> assert_has(Query.text("Turn On Additional Batteries"))
    |> click(Query.button("Create Project"))
    |> assert_has(Query.text(project_name, minimum: 1))
  end

  test "can start a bare project", %{session: session, control_url: url} do
    project_name = "bare-#{:rand.uniform(10_000)}"

    session
    |> visit(url)
    |> assert_has(Query.text("Home", minimum: 1))
    |> click(Query.link("New Project"))
    |> fill_in(Query.text_field("project[name]"), with: project_name)
    |> find(Query.select("Project Type"), fn select ->
      click(select, Query.option("Bare Project"))
    end)
    |> click(Query.button("Next Step"))
    |> click(Query.button("Create Project"))
    |> assert_has(Query.text(project_name, minimum: 1))
  end
end
