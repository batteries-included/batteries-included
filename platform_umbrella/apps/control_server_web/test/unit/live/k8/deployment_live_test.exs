defmodule ControlServerWeb.Live.DeployementLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServerWeb.ResourceFixtures
  import Phoenix.LiveViewTest

  alias ControlServerWeb.Resource
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

    test "displays deployment", %{conn: conn, deployment: deployment} do
      {:ok, _show_live, html} =
        live(conn, ~p"/kube/deployment/#{Resource.namespace(deployment)}/#{Resource.name(deployment)}")

      assert html =~ Resource.name(deployment)

      conditions = Resource.conditions(deployment)
      assert html =~ get_in(conditions, [Access.at(0), "type"])

      labels = Resource.labels(deployment)
      {label_key, label_value} = Enum.at(Map.to_list(labels), 0)
      assert html =~ label_key
      assert html =~ label_value
    end
  end
end
