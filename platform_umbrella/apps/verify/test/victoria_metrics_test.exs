defmodule Verify.VictoriaMetricsTest do
  use Verify.TestCase, async: false, batteries: ~w(victoria_metrics)a, images: ~w(grafana vm_operator)a

  verify "victoria metrics is running", %{session: session} do
    session =
      session
      |> assert_pod_running("vm-operator")
      |> assert_pod_running("vmagent-main-agent")
      |> assert_pod_running("vmstorage-main-cluster-0")
      |> assert_pod_running("vmselect-main-cluster-0")
      |> assert_pod_running("vminsert-main-cluster-")
      |> visit("/monitoring")

    handle = window_handle(session)

    # check vm agent site
    session =
      session
      |> focus_window(handle)
      |> click_external(Query.css("a", text: "VM Agent"))
      |> assert_has(Query.css("h2", text: "vmagent"))
      |> close_window()

    # check vm select site
    session
    |> focus_window(handle)
    |> click_external(Query.css("a", text: "VM Select"))
    |> assert_has(Query.css("a.vm-link", text: "victoriametrics.com"))
    |> close_window()
  end
end
