defmodule Verify.VictoriaMetricsTest do
  use Verify.Images

  use Verify.TestCase,
    async: false,
    batteries: ~w(victoria_metrics)a,
    images: ~w(grafana)a ++ @victoria_metrics

  verify "victoria metrics is running", %{session: session} do
    ns = "battery-core"

    session
    # these are roughly the order that these are created
    # so check each in turn
    |> assert_pods_in_deployment_running(ns, "vm-operator")
    |> assert_pods_in_deployment_running(ns, "vmagent-main-agent")
    |> assert_pods_in_sts_running(ns, "vmstorage-main-cluster")
    |> assert_pods_in_sts_running(ns, "vmselect-main-cluster")
    |> assert_pods_in_deployment_running(ns, "vminsert-main-cluster")
    # now try to access the running services
    |> visit("/monitoring")
    |> click_external(Query.css("a", text: "VM Agent"))
    |> assert_has(Query.css("h2", text: "vmagent"))
    |> close_tab()
    |> click_external(Query.css("a", text: "VM Select"))
    |> assert_has(Query.css("a.vm-link", text: "victoriametrics.com"))
  end
end
