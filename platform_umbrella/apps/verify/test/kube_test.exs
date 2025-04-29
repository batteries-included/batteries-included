defmodule Verify.KubeTest do
  use Verify.TestCase, async: false

  @pod_path "/kube/pods"

  verify "can show kubernetes state", %{session: session} do
    session
    |> visit(@pod_path)
    |> assert_has(table_row(minimum: 6))
    |> click(Query.link("Deployments"))
    |> assert_has(table_row(minimum: 1))
    |> click(Query.link("Services"))
    |> assert_has(table_row(minimum: 4))
    |> click(Query.link("Nodes"))
    |> assert_has(table_row(minimum: 1))
    |> click(Query.link("Pods"))
    |> assert_has(table_row(minimum: 6))
  end

  verify "can filter to show only one kubernetes pod", %{session: session} do
    session
    |> visit(@pod_path)
    |> assert_has(table_row(minimum: 6))
    |> fill_in(Query.text_field("filter_value"), with: "pg-controlserver-1")
    |> assert_has(table_row(count: 1))
  end

  verify "can filter to nothing", %{session: session} do
    session
    |> visit(@pod_path)
    |> assert_has(table_row(minimum: 6))
    |> fill_in(Query.text_field("filter_value"), with: "some-value-that-does-not-exist")
    |> assert_has(table_row(count: 0))
  end
end
