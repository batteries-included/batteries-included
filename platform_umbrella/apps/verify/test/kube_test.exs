defmodule Verify.KubeTest do
  use Verify.TestCase, async: false

  @tag :cluster_test
  test "Can show kubernetes state", %{session: session, control_url: url} do
    session
    |> visit(url <> "/kube/pods")
    |> assert_has(Query.css("table tbody tr", minimum: 6))
    |> click(Query.link("Deployments"))
    |> assert_has(Query.css("table tbody tr", minimum: 1))
    |> click(Query.link("Services"))
    |> assert_has(Query.css("table tbody tr", minimum: 4))
    |> click(Query.link("Nodes"))
    |> assert_has(Query.css("table tbody tr", minimum: 1))
    |> click(Query.link("Pods"))
    |> assert_has(Query.css("table tbody tr", minimum: 6))
  end

  @tag :cluster_test
  test "Can filter to show only one kubernetes pod", %{session: session, control_url: url} do
    session
    |> visit(url <> "/kube/pods")
    |> assert_has(Query.css("table tbody tr", minimum: 6))
    |> fill_in(Query.text_field("filter_value"), with: "pg-controlserver-1")
    |> assert_has(Query.css("table tbody tr", count: 1))
  end

  @tag :cluster_test
  test "can filter to nothing", %{session: session, control_url: url} do
    session
    |> visit(url <> "/kube/pods")
    |> assert_has(Query.css("table tbody tr", minimum: 6))
    |> fill_in(Query.text_field("filter_value"), with: "some-value-that-does-not-exist")
    |> assert_has(Query.css("table tbody tr", count: 0))
  end
end
