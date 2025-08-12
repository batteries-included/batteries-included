defmodule ControlServerWeb.Live.PodLiveTest do
  use ControlServerWeb.ConnCase

  import CommonCore.ResourceFactory
  import CommonCore.Resources.FieldAccessors
  import Phoenix.LiveViewTest

  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_pod(_) do
    pod = build(:pod)
    Runner.add(@table_name, pod)

    on_exit(fn ->
      Runner.delete(@table_name, pod)
    end)

    %{pod: pod}
  end

  describe "show" do
    setup [:create_pod]

    test "displays pod", %{conn: conn, pod: pod} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/pod/#{namespace(pod)}/#{name(pod)}/show")
      assert html =~ name(pod)

      container_statuses = container_statuses(pod)
      assert html =~ get_in(container_statuses, [Access.at(0), "name"])
    end
  end

  describe "labels" do
    setup [:create_pod]

    test "displays pod labels", %{conn: conn, pod: pod} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/pod/#{namespace(pod)}/#{name(pod)}/labels")

      labels = labels(pod)
      {label_key, label_value} = Enum.at(Map.to_list(labels), 0)
      assert html =~ label_key
      assert html =~ label_value
    end
  end

  describe "events" do
    setup [:create_pod]

    test "displays pod events", %{conn: conn, pod: pod} do
      {:ok, _show_live, _html} = live(conn, ~p"/kube/pod/#{namespace(pod)}/#{name(pod)}/events")
    end
  end
end
