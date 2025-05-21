defmodule Verify.KubeMonitoringTest do
  use Verify.TestCase, async: false, batteries: ~w(kube_monitoring)a

  verify "kube_monitoring is running", %{session: session} do
    session
    |> assert_pod_running("kube-state-metrics")
    |> assert_pod_running("metrics-server")
    |> assert_pod_running("node-exporter")

    # TODO: assert that metrics are being scrapped and sent to victoria metrics
  end
end
