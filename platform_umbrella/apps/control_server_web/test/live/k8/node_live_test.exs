defmodule ControlServerWeb.Live.NodeLiveTest do
  use ControlServerWeb.ConnCase

  import CommonCore.ResourceFactory
  import CommonCore.Resources.FieldAccessors
  import Phoenix.LiveViewTest

  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_node(_) do
    node = build(:node)
    Runner.add(@table_name, node)

    on_exit(fn ->
      Runner.delete(@table_name, node)
    end)

    %{node: node}
  end

  describe "show" do
    setup [:create_node]

    test "displays node", %{conn: conn, node: node} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/node/#{name(node)}/show")
      assert html =~ name(node)

      # Check that the main sections are displayed
      assert html =~ "Node Details"
      assert html =~ "Ready Status"
      assert html =~ "Network Addresses"

      # Check that node info is displayed if available
      node_info = get_in(node, ~w(status nodeInfo))

      if node_info do
        assert html =~ "System Information"
      end
    end

    test "displays node network addresses", %{conn: conn, node: node} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/node/#{name(node)}/show")

      # Check that network addresses are displayed
      addresses = get_in(node, ~w(status addresses)) || []

      for address <- addresses do
        address_value = Map.get(address, "address", "")

        if address_value != "" do
          assert html =~ address_value
        end
      end
    end

    test "displays node system information", %{conn: conn, node: node} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/node/#{name(node)}/show")

      # Check that system information is displayed
      node_info = get_in(node, ~w(status nodeInfo))

      if node_info do
        os_image = Map.get(node_info, "osImage")
        architecture = Map.get(node_info, "architecture")

        if os_image, do: assert(html =~ os_image)
        if architecture, do: assert(html =~ architecture)
      end
    end
  end

  describe "events" do
    setup [:create_node]

    test "displays node events", %{conn: conn, node: node} do
      {:ok, _show_live, _html} = live(conn, ~p"/kube/node/#{name(node)}/events")
    end
  end

  describe "pods" do
    setup [:create_node]

    test "displays node pods", %{conn: conn, node: node} do
      {:ok, _show_live, _html} = live(conn, ~p"/kube/node/#{name(node)}/pods")
    end
  end

  describe "labels" do
    setup [:create_node]

    test "displays node labels", %{conn: conn, node: node} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/node/#{name(node)}/labels")

      labels = labels(node)
      {label_key, label_value} = Enum.at(Map.to_list(labels), 0)
      assert html =~ label_key
      assert html =~ label_value
    end
  end

  describe "annotations" do
    setup [:create_node]

    test "displays node annotations", %{conn: conn, node: node} do
      {:ok, _show_live, _html} = live(conn, ~p"/kube/node/#{name(node)}/annotations")
    end
  end
end
