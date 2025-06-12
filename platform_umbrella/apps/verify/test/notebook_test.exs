defmodule Verify.NotebookTest do
  use Verify.TestCase, async: false, batteries: ~w(notebooks)a, images: ~w(jupyter_datascience_lab)a

  @new_notebook_path "/notebooks/new"
  @show_notebook_path ~r(/notebooks/[\d\w-]+$)

  verify "can create notebook", %{session: session} do
    notebook_name = "int-test-#{:rand.uniform(10_000)}"

    session
    # create notebook
    |> visit(@new_notebook_path)
    |> assert_has(h3("New Jupyter Notebook"))
    |> fill_in_name("jupyter_lab_notebook[name]", notebook_name)
    |> click(Query.button("Save Notebook"))
    # verify we're on the show page
    |> assert_has(h3(notebook_name))
    |> assert_path(@show_notebook_path)
    |> assert_has(Query.text("Image"))
    |> assert_has(Query.text("Storage Size"))
    |> assert_has(Query.text("Memory limits"))
    # make sure notebook is running
    |> assert_pod_running(notebook_name)
    # make sure we can access the running notebook
    |> visit_running_service("Open Notebook")
    |> assert_has(Query.css("div#main"))
  end
end
