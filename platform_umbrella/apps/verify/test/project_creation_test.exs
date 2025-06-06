defmodule Verify.ProjectCreationTest do
  use Verify.TestCase, async: false

  @home_path "/"
  @home_header h3("Home", minimum: 1)
  @new_project_link Query.link("New Project")
  @project_name_field Query.text_field("project[name]")
  @type_select Query.select("Project Type")
  @next_step_button Query.button("Next Step")
  @create_project_button Query.button("Create Project")

  verify "can start a demo like project", %{session: session} do
    project_name = "pastebin-#{:rand.uniform(10_000)}"

    session
    |> visit(@home_path)
    |> assert_has(@home_header)
    |> click(@new_project_link)
    |> fill_in(@project_name_field, with: project_name)
    |> find(@type_select, &click(&1, Query.option("Web")))
    |> click(@next_step_button)
    |> click(Query.text("I need a database"))
    |> touch_scroll(Query.text("Next Step"), 0, 0)
    |> click(@next_step_button)
    |> assert_has(Query.text("Turn On Additional Batteries"))
    |> click(@create_project_button)
    |> assert_has(h3(project_name, minimum: 1))
  end

  verify "can start a bare project", %{session: session} do
    project_name = "bare-#{:rand.uniform(10_000)}"

    session
    |> visit(@home_path)
    |> assert_has(@home_header)
    |> click(@new_project_link)
    |> fill_in(@project_name_field, with: project_name)
    |> find(@type_select, &click(&1, Query.option("Bare Project")))
    |> click(@next_step_button)
    |> click(@create_project_button)
    |> assert_has(h3(project_name, minimum: 1))
  end
end
