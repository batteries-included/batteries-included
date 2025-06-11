defmodule Verify.OllamaTest do
  use Verify.TestCase, async: false, batteries: ~w(ollama)a

  @new_model_path "/model_instances/new"
  @show_model_path ~r(/model_instances/[\d\w-]+/show$)

  setup_all do
    image =
      :ollama
      |> CommonCore.Defaults.Images.get_image!()
      |> CommonCore.Defaults.Image.default_image()

    # this is maybe a little brittle but it helps the tests pass by pre-pulling the ollama image
    Logger.debug("Pre-pulling ollama image: #{image}")
    {_, 0} = System.cmd("docker", ~w[exec int-test-control-plane crictl pull] ++ [image])
    :ok
  end

  verify "can create model", %{session: session} do
    model_name = "int-test-#{:rand.uniform(10_000)}"

    session
    # create model
    |> visit(@new_model_path)
    |> assert_has(h3("New Ollama Model"))
    |> fill_in_name("model_instance[name]", model_name)
    # select the smallest model
    |> find(Query.select("Model"), &click(&1, Query.option("Nomic embed-text 137m (274MB)")))
    |> click(Query.button("Save Model"))
    # verify we're on the show page
    |> assert_has(h3(model_name))
    |> assert_path(@show_model_path)
    # Make sure that this page has the kubernetes elements
    |> assert_has(Query.text("Pods"))
    |> click(Query.text("Pods"))
    # Assert that the pod is created
    |> assert_has(table_row(text: model_name, count: 1))
    # make sure model is running
    |> assert_pod_running(model_name)
  end
end
