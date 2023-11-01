defmodule ControlServerWeb.Live.ResourcesListTest do
  use ControlServerWeb.ConnCase

  import ControlServerWeb.ResourceFixtures
  import Phoenix.LiveViewTest

  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_resources(_) do
    resources = [
      resource_fixture(%{kind: "Pod"}),
      resource_fixture(%{kind: "Pod"}),
      resource_fixture(%{kind: "Deployment"}),
      resource_fixture(%{kind: "Deployment"}),
      resource_fixture(%{kind: "StatefulSet"}),
      resource_fixture(%{kind: "StatefulSet"}),
      resource_fixture(%{kind: "Service"}),
      resource_fixture(%{kind: "Service"}),
      resource_fixture(%{kind: "Node"}),
      resource_fixture(%{kind: "Node"})
    ]

    Enum.each(resources, fn resource ->
      Runner.add(@table_name, resource)
    end)

    on_exit(fn ->
      Enum.each(resources, fn resource ->
        Runner.delete(@table_name, resource)
      end)
    end)

    %{
      resources: resources
    }
  end

  describe "list resources" do
    setup [:create_resources]

    test "displays pods", %{conn: conn, resources: resources} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/pods")
      pods = Enum.filter(resources, &(K8s.Resource.kind(&1) == "Pod"))

      assert html =~ "Pods"
      assert html =~ K8s.Resource.name(Enum.at(pods, 0))
      assert html =~ K8s.Resource.name(Enum.at(pods, 0))
    end

    test "displays deployments", %{conn: conn, resources: resources} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/deployments")
      deployments = Enum.filter(resources, &(K8s.Resource.kind(&1) == "Deployment"))

      assert html =~ "Deployments"
      assert html =~ K8s.Resource.name(Enum.at(deployments, 0))
      assert html =~ K8s.Resource.name(Enum.at(deployments, 0))
    end

    test "displays stateful sets", %{conn: conn, resources: resources} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/stateful_sets")
      stateful_sets = Enum.filter(resources, &(K8s.Resource.kind(&1) == "StatefulSet"))

      assert html =~ "Stateful Sets"
      assert html =~ K8s.Resource.name(Enum.at(stateful_sets, 0))
      assert html =~ K8s.Resource.name(Enum.at(stateful_sets, 0))
    end

    test "displays services", %{conn: conn, resources: resources} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/services")
      services = Enum.filter(resources, &(K8s.Resource.kind(&1) == "Service"))

      assert html =~ "Stateful Sets"
      assert html =~ K8s.Resource.name(Enum.at(services, 0))
      assert html =~ K8s.Resource.name(Enum.at(services, 0))
    end

    test "displays nodes", %{conn: conn, resources: resources} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/nodes")
      nodes = Enum.filter(resources, &(K8s.Resource.kind(&1) == "Node"))

      assert html =~ "Stateful Sets"
      assert html =~ K8s.Resource.name(Enum.at(nodes, 0))
      assert html =~ K8s.Resource.name(Enum.at(nodes, 0))
    end
  end

  describe "show message when no resources" do
    test "pods", %{conn: conn} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/pods")
      assert html =~ "No pods"
    end

    test "deployments", %{conn: conn} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/deployments")
      assert html =~ "No deployments"
    end

    test "stateful_sets", %{conn: conn} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/stateful_sets")
      assert html =~ "No stateful sets"
    end

    test "nodes", %{conn: conn} do
      {:ok, _show_live, html} = live(conn, ~p"/kube/nodes")
      assert html =~ "No nodes"
    end
  end
end
