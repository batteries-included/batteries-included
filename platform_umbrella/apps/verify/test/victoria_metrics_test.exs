defmodule Verify.VictoriaMetricsTest do
  use Verify.Images

  use Verify.TestCase,
    async: false,
    batteries: ~w(victoria_metrics)a,
    images: ~w(grafana)a ++ @victoria_metrics

  verify "victoria metrics is running", %{session: session} do
    session
    |> assert_pod_running("vm-operator")
    |> assert_pod_running("vmagent-main-agent")
    |> assert_pod_running("vmstorage-main-cluster-0")
    |> assert_pod_running("vmselect-main-cluster-0")
    |> assert_pod_running("vminsert-main-cluster-")
    |> visit("/monitoring")
    |> click_external(Query.css("a", text: "VM Agent"))
    |> assert_has(Query.css("h2", text: "vmagent"))
    |> close_tab()
    |> click_external(Query.css("a", text: "VM Select"))
    |> assert_has(Query.css("a.vm-link", text: "victoriametrics.com"))
  end
end
