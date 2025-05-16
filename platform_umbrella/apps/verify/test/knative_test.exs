defmodule Verify.KnativeTest do
  use Verify.TestCase, async: false, batteries: ~w(knative)a

  @new_knative_path "/knative/services/new"
  @knative_ns "battery-knative"
  @show_knative_path ~r(/knative/services/[\d\w-]+/show$)

  # make sure knative is fully running before tests start
  setup_all do
    {:ok, session} = Verify.TestCase.start_session()

    # TODO(jdt): try to get rid of this!
    # wait a sec for knative to "install"
    Process.sleep(5_000)

    session
    # trigger a new summary
    |> trigger_k8s_deploy()
    # wait for a sec for it to complete
    |> then(fn session ->
      Process.sleep(1_000)
      session
    end)
    |> assert_pods_in_deployment_running(@knative_ns, "activator")
    |> assert_pods_in_deployment_running(@knative_ns, "autoscaler")
    |> assert_pods_in_deployment_running(@knative_ns, "controller")
    |> assert_pods_in_deployment_running(@knative_ns, "net-istio-controller")
    |> assert_pods_in_deployment_running(@knative_ns, "webhook")

    Wallaby.end_session(session)
  end

  @container_panel Query.css("#containers_panel-containers")

  verify "can create knative service", %{session: session} do
    service_name = "int-test-#{:rand.uniform(10_000)}"

    session
    # create service
    |> visit(@new_knative_path)
    |> assert_has(h3("New Knative Service"))
    |> fill_in_name("service[name]", service_name)
    # add container
    |> find(@container_panel, fn e -> click(e, Query.button("Add Container")) end)
    |> fill_in(Query.text_field("container[name]"), with: "echo")
    |> fill_in(Query.text_field("container[image]"), with: "ealen/echo-server:latest")
    |> click(Query.css(~s/#container-form-modal-modal-container button[type="submit"]/))
    |> click(Query.button("Save Knative Service"))
    # verify we're on the show page
    |> assert_has(h3(service_name))
    |> assert_path(@show_knative_path)
    # Make sure that this page has the kubernetes elements
    |> assert_has(Query.text("Pods"))
    |> click(Query.text("Pods"))
    # Assert that the first pod for the cluster is there.
    |> assert_has(table_row(text: service_name, count: 1))
    # this may be flakey with the way knative scales down to 0 /shrug
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
