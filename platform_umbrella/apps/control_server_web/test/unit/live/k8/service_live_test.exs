defmodule ControlServerWeb.Live.ServiceLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServerWeb.ResourceFixtures
  import Phoenix.LiveViewTest

  alias ControlServerWeb.Resource
  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_service(_) do
    service = resource_fixture(%{kind: "Service"})
    Runner.add(@table_name, service)

    on_exit(fn ->
      Runner.delete(@table_name, service)
    end)

    %{service: service}
  end

  describe "show" do
    setup [:create_service]

    test "displays service", %{conn: conn, service: service} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/service/#{Resource.namespace(service)}/#{Resource.name(service)}")

      assert html =~ Resource.name(service)

      labels = Resource.labels(service)
      {label_key, label_value} = Enum.at(Map.to_list(labels), 0)
      assert html =~ label_key
      assert html =~ label_value
    end
  end
end
