defmodule ControlServerWeb.Live.StatefulSetLiveTest do
  use ControlServerWeb.ConnCase

  import CommonCore.Resources.FieldAccessors
  import ControlServer.ResourceFixtures
  import Phoenix.LiveViewTest

  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_stateful_set(_) do
    stateful_set = resource_fixture(%{kind: "StatefulSet"})
    Runner.add(@table_name, stateful_set)

    on_exit(fn ->
      Runner.delete(@table_name, stateful_set)
    end)

    %{stateful_set: stateful_set}
  end

  describe "show" do
    setup [:create_stateful_set]

    test "displays stateful_set labels", %{conn: conn, stateful_set: stateful_set} do
      {:ok, _show_live, html} =
        live(conn, ~p"/kube/stateful_set/#{namespace(stateful_set)}/#{name(stateful_set)}/labels")

      assert html =~ name(stateful_set)

      labels = labels(stateful_set)
      {label_key, label_value} = Enum.at(Map.to_list(labels), 0)
      assert html =~ label_key
      assert html =~ label_value
    end
  end
end
