defmodule Verify.KubeTest do
  use Verify.TestCase, async: false

  @moduletag :cluster_test

  verify "Can show kubernetes state", %{session: session, control_url: url} do
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

  verify "Can filter to show only one kubernetes pod", %{session: session, control_url: url} do
    session
    |> visit(url <> "/kube/pods")
    |> assert_has(Query.css("table tbody tr", minimum: 6))
    |> fill_in(Query.text_field("filter_value"), with: "pg-controlserver-1")
    |> assert_has(Query.css("table tbody tr", count: 1))
  end

  verify "can filter to nothing", %{session: session, control_url: url} do
    session
    |> visit(url <> "/kube/pods")
    |> assert_has(Query.css("table tbody tr", minimum: 6))
    |> fill_in(Query.text_field("filter_value"), with: "some-value-that-does-not-exist")
    |> assert_has(Query.css("table tbody tr", count: 0))
  end
end
