defmodule ControlServerWeb.PostgresLiveTest do
  use Heyya.LiveTest
  use ControlServerWeb.ConnCase

  import ControlServer.ClusterFixtures
  import ControlServer.ResourceFixtures

  alias CommonCore.Postgres.Cluster
  alias ControlServer.Repo
  alias KubeServices.KubeState.Runner

  @kube_table_name :default_state_table
  @valid_attrs %{
    cluster: %{
      name: "PostgresLiveTest",
      virtual_size: "small",
      num_instances: 1
    }
  }
  @update_attrs %{
    cluster: %{
      name: "ANewName",
      virtual_size: "medium",
      num_instances: 3
    }
  }

  defp create_namespace(_) do
    namespace = resource_fixture(%{kind: "Namespace"})
    Runner.add(@kube_table_name, namespace)

    on_exit(fn ->
      Runner.delete(@kube_table_name, namespace)
    end)

    %{namespace: namespace}
  end

  describe "index" do
    test "renders a list of postgres clusters", %{conn: conn} do
      cluster_one = cluster_fixture()
      cluster_two = cluster_fixture()

      conn
      |> start(~p|/postgres|)
      |> assert_html("Postgres Clusters")
      |> assert_html(cluster_one.name)
      |> assert_html(cluster_two.name)
    end
  end

  describe "new" do
    setup [:create_namespace]

    test "create new cluster", %{conn: conn} do
      assert is_nil(Repo.get_by(Cluster, name: @valid_attrs.cluster.name))

      conn
      |> start(~p"/postgres/new")
      |> submit_form("#cluster-form", @valid_attrs)

      assert not is_nil(Repo.get_by(Cluster, name: @valid_attrs.cluster.name))
    end

    test "changing the virtual size field to custom exposes storage fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/postgres/new")

      html =
        assert view
               |> element("#cluster-form")
               |> render_change(%{cluster: %{virtual_size: "custom"}})

      assert html =~ "Storage Class"
      assert html =~ "Storage Size"
    end

    test "can add a user", %{conn: conn} do
      valid_user_params = %{"roles" => ["inherit", "replication"], "username" => "a_new_user"}

      conn
      |> start(~p|/postgres/new|)
      |> click("button", "New user")
      |> submit_form("#user_modal form", %{"pg_user" => valid_user_params})
      |> assert_html(valid_user_params["username"])
      |> assert_html("inherit")
      |> assert_html("replication")
      |> submit_form("#cluster-form", @valid_attrs)

      cluster = Repo.get_by(Cluster, name: @valid_attrs.cluster.name)
      assert Enum.find(cluster.users, &(&1.roles == valid_user_params["roles"]))
    end

    test "can delete a user", %{conn: conn} do
      valid_user_params = %{"roles" => ["inherit", "replication"], "username" => "a_new_user"}

      conn
      |> start(~p|/postgres/new|)
      |> click("button", "New user")
      |> submit_form("#user_modal form", %{"pg_user" => valid_user_params})
      |> assert_html(valid_user_params["username"])
      |> click("#delete_user_#{valid_user_params["username"]}")
      |> submit_form("#cluster-form", @valid_attrs)

      cluster = Repo.get_by(Cluster, name: @valid_attrs.cluster.name)
      refute Enum.find(cluster.users, &(&1.roles == valid_user_params["roles"]))
    end

    test "can add a credential_copy", %{conn: conn, namespace: namespace} do
      valid_cc_params = %{"format" => "dsn", "namespace" => namespace["metadata"]["name"], "username" => "app"}

      conn
      |> start(~p|/postgres/new|)
      |> click("button", "New copy")
      |> submit_form("#credential_copy_modal form", %{"pg_credential_copy" => valid_cc_params})
      |> assert_html(valid_cc_params["username"])
      |> submit_form("#cluster-form", @valid_attrs)

      cluster = Repo.get_by(Cluster, name: @valid_attrs.cluster.name)
      assert Enum.find(cluster.credential_copies, &(&1.username == valid_cc_params["username"]))
    end

    test "can delete a credential_copy", %{conn: conn, namespace: namespace} do
      valid_cc_params = %{"format" => "dsn", "namespace" => namespace["metadata"]["name"], "username" => "app"}

      conn
      |> start(~p|/postgres/new|)
      |> click("button", "New copy")
      |> submit_form("#credential_copy_modal form", %{"pg_credential_copy" => valid_cc_params})
      |> assert_html(valid_cc_params["username"])
      |> click("#delete_credential_copy_#{valid_cc_params["namespace"]}_#{valid_cc_params["username"]}")
      |> submit_form("#cluster-form", @valid_attrs)

      cluster = Repo.get_by(Cluster, name: @valid_attrs.cluster.name)
      refute Enum.find(cluster.credential_copies, &(&1.username == valid_cc_params["username"]))
    end
  end

  describe "edit" do
    defp setup_edit(_) do
      namespace = resource_fixture(%{kind: "Namespace"})
      Runner.add(@kube_table_name, namespace)

      on_exit(fn ->
        Runner.delete(@kube_table_name, namespace)
      end)

      cluster = cluster_fixture(%{virtual_size: "small"})

      %{namespace: namespace, cluster: cluster}
    end

    setup [:setup_edit]

    test "can edit an existing cluster", %{conn: conn, cluster: cluster} do
      conn
      |> start(~p"/postgres/#{cluster}/edit")
      |> submit_form("#cluster-form", @update_attrs)

      updated_cluster = Repo.get(Cluster, cluster.id)
      assert updated_cluster.name == @update_attrs.cluster.name
    end

    test "changing the virtual size field to custom exposes storage fields and defaults to the existing storage size", %{
      conn: conn,
      cluster: cluster
    } do
      {:ok, view, html} = live(conn, ~p"/postgres/#{cluster}/edit")
      assert html =~ ~s|<option selected="selected" value="small">Small</option>|

      html =
        assert view
               |> element("#cluster-form")
               |> render_change(%{cluster: %{virtual_size: "custom"}})

      assert html =~ "Storage Class"
      assert html =~ CommonCore.Util.Memory.format_bytes(cluster.storage_size, true)
    end
  end
end
