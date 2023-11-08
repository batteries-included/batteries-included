defmodule ControlServerWeb.Live.PodLiveTest do
  use ControlServerWeb.ConnCase

  import CommonCore.Resources.FieldAccessors
  import ControlServer.ResourceFixtures
  import Phoenix.LiveViewTest

  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_pod(_) do
    pod = resource_fixture(%{kind: "Pod"})
    Runner.add(@table_name, pod)

    on_exit(fn ->
      Runner.delete(@table_name, pod)
    end)

    %{pod: pod}
  end

  describe "show" do
    setup [:create_pod]

    test "displays pod", %{conn: conn, pod: pod} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/pod/#{namespace(pod)}/#{name(pod)}")
      assert html =~ name(pod)

      conditions = conditions(pod)
      assert html =~ get_in(conditions, [Access.at(0), "type"])

      container_statuses = container_statuses(pod)
      assert html =~ get_in(container_statuses, [Access.at(0), "name"])

      labels = labels(pod)
      {label_key, label_value} = Enum.at(Map.to_list(labels), 0)
      assert html =~ label_key
      assert html =~ label_value
    end
  end
end
