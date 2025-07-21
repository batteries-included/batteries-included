defmodule Verify.KubeMonitoringTest do
  use Verify.Images

  use Verify.TestCase,
    async: false,
    batteries: ~w(kube_monitoring)a,
    images: ~w(kube_state_metrics node_exporter metrics_server addon_resizer)a ++ @victoria_metrics

  verify "kube_monitoring is running", %{session: session} do
    session
    # make sure all pods are running first
    |> assert_pod_running("kube-state-metrics")
    |> assert_pod_running("metrics-server")
    |> assert_pod_running("node-exporter")
    |> assert_pod_running("vm-operator")
    |> assert_pod_running("vmagent-main-agent-")
    |> assert_pod_running("vmstorage-main-cluster-0")
    |> assert_pod_running("vmselect-main-cluster-0")
    |> assert_pod_running("vminsert-main-cluster-")
    # check that the agent has scraped samples
    |> visit("/monitoring")
    |> visit_running_service("VM Agent")
    |> sleep(15_000)
    |> click(Query.css(~s|a[href="targets"]|))
    |> click(Query.button("Filter targets"))
    |> fill_in(Query.text_field("label_search"), with: ~s|{job="node-exporter"}|)
    |> wait_for_samples_scraped()
    |> close_tab()
    # initial check of vmui
    |> visit("/monitoring")
    |> visit_running_service("VM Select")
    |> assert_text("victoriametrics.com")
  end

  defp wait_for_samples_scraped(session) do
    submit_button = Query.button("Submit")
    samples_query = Query.css("tr td:nth-child(10)")

    # retry until we find the target
    retry(fn ->
      session
      |> sleep(250)
      |> click(submit_button)
      |> execute_query_without_retry(samples_query)
    end)

    retry(fn ->
      case session |> text(samples_query) |> Integer.parse() do
        # found the element
        {count, _} when count > 0 ->
          {:ok, count}

        result ->
          session |> sleep(250) |> click(submit_button)
          {:error, result}
      end
    end)

    session
  end
end
