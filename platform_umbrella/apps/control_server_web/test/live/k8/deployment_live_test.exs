defmodule ControlServerWeb.Live.DeployementLiveTest do
  use ControlServerWeb.ConnCase

  import CommonCore.Resources.FieldAccessors
  import ControlServer.ResourceFixtures
  import Phoenix.LiveViewTest

  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_deployment(_) do
    deployment = resource_fixture(%{kind: "Deployment"})
    Runner.add(@table_name, deployment)

    on_exit(fn ->
      Runner.delete(@table_name, deployment)
    end)

    %{deployment: deployment}
  end

  describe "show" do
    setup [:create_deployment]

    test "displays deployment conditions", %{conn: conn, deployment: deployment} do
      {:ok, _show_live, html} =
        live(conn, ~p"/kube/deployment/#{namespace(deployment)}/#{name(deployment)}/show")

      assert html =~ name(deployment)

      conditions = conditions(deployment)
      assert html =~ get_in(conditions, [Access.at(0), "type"])
    end

    test "displays deployment labels", %{conn: conn, deployment: deployment} do
      {:ok, _show_live, html} =
        live(conn, "/kube/deployment/#{namespace(deployment)}/#{name(deployment)}/labels")

      assert html =~ name(deployment)

      labels = labels(deployment)
      {label_key, label_value} = Enum.at(Map.to_list(labels), 0)
      assert html =~ label_key
      assert html =~ label_value
    end
  end
end
