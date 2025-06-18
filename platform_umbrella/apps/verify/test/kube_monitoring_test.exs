defmodule Verify.KubeMonitoringTest do
  use Verify.Images

  use Verify.TestCase,
    async: false,
    batteries: ~w(kube_monitoring)a,
    images: ~w(kube_state_metrics node_exporter metrics_server addon_resizer)a ++ @victoria_metrics

  verify "kube_monitoring is running", %{session: session} do
    session
    |> assert_pod_running("kube-state-metrics")
    |> assert_pod_running("metrics-server")
    |> assert_pod_running("node-exporter")

    # TODO: assert that metrics are being scrapped and sent to victoria metrics
  end
end
