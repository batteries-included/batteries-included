defmodule Verify.KubeMonitoringTest do
  use Verify.TestCase,
    async: false,
    batteries: ~w(kube_monitoring)a,
    images: ~w(
      vm_operator 
      kube_state_metrics
      node_exporter
      metrics_server
      addon_resizer
      vm_insert
      vm_select
      vm_storage
      vm_agent
    )a

  verify "kube_monitoring is running", %{session: session} do
    session
    |> assert_pod_running("kube-state-metrics")
    |> assert_pod_running("metrics-server")
    |> assert_pod_running("node-exporter")

    # TODO: assert that metrics are being scrapped and sent to victoria metrics
  end
end
