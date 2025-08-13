defmodule ControlServerWeb.Live.ResourcesListTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import CommonCore.ResourceFactory

  alias KubeServices.KubeState.Runner

  @table_name :default_state_table

  defp create_resources(_) do
    resources = [
      build(:pod),
      build(:pod),
      build(:pod),
      build(:deployment),
      build(:deployment),
      build(:stateful_set),
      build(:stateful_set),
      build(:service),
      build(:service),
      build(:node),
      build(:node)
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
      pods = Enum.filter(resources, &(K8s.Resource.kind(&1) == "Pod"))

      conn
      |> start(~p"/kube/pods")
      |> assert_html("Pods")
      |> await_async(1000)
      |> then(fn session ->
        Enum.reduce(pods, session, fn pod, session -> assert_html(session, K8s.Resource.name(pod)) end)
      end)
    end

    test "displays deployments", %{conn: conn, resources: resources} do
      deployments = Enum.filter(resources, &(K8s.Resource.kind(&1) == "Deployment"))

      conn
      |> start(~p"/kube/deployments")
      |> assert_html("Deployments")
      |> await_async(1000)
      |> then(fn session ->
        Enum.reduce(deployments, session, fn deploy, session -> assert_html(session, K8s.Resource.name(deploy)) end)
      end)
    end

    test "displays stateful sets", %{conn: conn, resources: resources} do
      stateful_sets = Enum.filter(resources, &(K8s.Resource.kind(&1) == "StatefulSet"))

      conn
      |> start(~p"/kube/stateful_sets")
      |> assert_html("Stateful Sets")
      |> await_async(1000)
      |> then(fn session ->
        Enum.reduce(stateful_sets, session, fn stateful_set, session ->
          assert_html(session, K8s.Resource.name(stateful_set))
        end)
      end)
    end

    test "displays services", %{conn: conn, resources: resources} do
      services = Enum.filter(resources, &(K8s.Resource.kind(&1) == "Service"))

      conn
      |> start(~p"/kube/services")
      |> assert_html("Services")
      |> await_async(1000)
      |> then(fn session ->
        Enum.reduce(services, session, fn service, session ->
          assert_html(session, K8s.Resource.name(service))
        end)
      end)
    end

    test "displays nodes", %{conn: conn, resources: resources} do
      nodes = Enum.filter(resources, &(K8s.Resource.kind(&1) == "Node"))

      conn
      |> start(~p"/kube/nodes")
      |> assert_html("Nodes")
      |> await_async(1000)
      |> then(fn session ->
        Enum.reduce(nodes, session, fn node, session ->
          assert_html(session, K8s.Resource.name(node))
        end)
      end)
    end
  end

  describe "show message when no resources" do
    test "pods", %{conn: conn} do
      conn
      |> start(~p"/kube/pods")
      |> assert_html("Pods")
      |> await_async(1000)
      |> assert_html("No pods")
    end

    test "deployments", %{conn: conn} do
      conn
      |> start(~p"/kube/deployments")
      |> assert_html("Deployments")
      |> await_async(1000)
      |> assert_html("No deployments")
    end

    test "stateful_sets", %{conn: conn} do
      conn
      |> start(~p"/kube/stateful_sets")
      |> assert_html("Stateful Sets")
      |> await_async(1000)
      |> assert_html("No stateful sets")
    end

    test "nodes", %{conn: conn} do
      conn
      |> start(~p"/kube/nodes")
      |> assert_html("Nodes")
      |> await_async(1000)
      |> assert_html("No nodes")
    end
  end
end
