defmodule Verify.TraditionalTest do
  use Verify.TestCase, async: false, batteries: ~w(traditional_services)a

  require Logger

  @new_traditional_path "/traditional_services/new"
  @show_traditional_path ~r(/traditional_services/[\d\w-]+/show$)

  @container_panel Query.css("#containers_panel-containers")
  @port_panel Query.css("#ports_panel")

  verify "can create traditional service", %{session: session} do
    service_name = "int-test-#{:rand.uniform(10_000)}"

    session
    # create service
    |> visit(@new_traditional_path)
    |> assert_has(h3("New Traditional Service"))
    |> fill_in_name("service[name]", service_name)
    # add container
    |> find(@container_panel, fn e -> click(e, Query.button("Add Container")) end)
    |> fill_in(Query.text_field("container[name]"), with: "echo")
    |> fill_in(Query.text_field("container[image]"), with: "ealen/echo-server:latest")
    |> click(Query.css(~s/#container-form-modal-modal-container button[type="submit"]/))
    # make sure the modal is gone
    |> refute_has(Query.css("#container-form-modal"))
    |> sleep(100)
    # add port
    |> find(@port_panel, fn e -> click(e, Query.button("Add Port")) end)
    |> fill_in(Query.text_field("port[name]"), with: service_name)
    |> fill_in(Query.text_field("port[number]"), with: 80)
    |> click(Query.css(~s/#port-form-modal-modal-container button[type="submit"]/))
    # make sure the modal is gone
    |> refute_has(Query.css("#port-form-modal"))
    |> sleep(100)
    # save service
    |> click(Query.button("Save Traditional Service"))
    # verify we're on the show page
    |> assert_has(h3(service_name))
    |> assert_path(@show_traditional_path)
    # Make sure that this page has the kubernetes elements
    |> assert_has(Query.text("Pods"))
    |> click(Query.text("Pods"))
    # Assert that the first pod for the cluster is there.
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
