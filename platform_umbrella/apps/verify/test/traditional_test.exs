defmodule Verify.TraditionalTest do
  use Verify.Images
  use Verify.TestCase, async: false, batteries: ~w(traditional_services)a, images: [@echo_server]

  require Logger

  @show_traditional_path ~r(/traditional_services/[\d\w-]+/show$)

  verify "can create traditional service", %{session: session} do
    service_name = "int-test-#{:rand.uniform(10_000)}"

    session
    |> create_traditional_service(@echo_server, service_name)
    # verify we're on the show page
    |> assert_has(h3(service_name))
    |> assert_path(@show_traditional_path)
    # Make sure that this page has the kubernetes elements
    |> assert_has(Query.text("Pods"))
    |> click(Query.text("Pods"))
    # Assert that the first pod is there.
    |> assert_has(table_row(text: service_name, count: 1))
    |> assert_pod_running(service_name)
    # make sure we can access the running service
    |> visit_running_service()
    # get json text
    |> text()
    |> Jason.decode!()
    |> then(fn json ->
      assert ^service_name <> _rest = get_in(json, ["host", "hostname"])
      assert ^service_name <> _rest = get_in(json, ["environment", "HOSTNAME"])
    end)
  end
end
