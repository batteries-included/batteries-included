defmodule ControlServerWeb.PostgresLiveTest do
  use Heyya.LiveCase, async: false
  use ControlServerWeb.ConnCase

  import ControlServer.Factory
  import ControlServer.ResourceFixtures

  alias CommonCore.Postgres.Cluster
  alias ControlServer.Repo
  alias KubeServices.KubeState.Runner

  @kube_table_name :default_state_table
  @valid_attrs %{
    cluster: %{
      name: "postgres-live-test",
      virtual_size: "small",
      num_instances: 1
    }
  }
  @update_attrs %{
    cluster: %{
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
      cluster_one = insert(:postgres_cluster)
      cluster_two = insert(:postgres_cluster)

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

    test "create a cluster with project", %{conn: conn} do
      project = insert(:project)

      params =
        :postgres_cluster
        |> params_for(project_id: project.id)
        |> Map.drop(
          ~w(id users project type storage_class storage_size database password_versions cpu_limits memory_limits cpu_requested memory_requested)a
        )

      conn
      |> start(~p"/postgres/new")
      |> submit_form("#cluster-form", cluster: params)

      cluster = Repo.get_by(Cluster, name: params.name)
      assert cluster.project_id == project.id
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
      |> click("button", "New User")
      |> submit_form("#user-form", %{"pg_user" => valid_user_params})
      |> assert_html(valid_user_params["username"])
      |> assert_html("inherit")
      |> assert_html("replication")
      |> submit_form("#cluster-form", @valid_attrs)

      cluster = Repo.get_by(Cluster, name: @valid_attrs.cluster.name)
      assert Enum.find(cluster.users, &(&1.roles == valid_user_params["roles"]))
    end

    test "can create a cluster with user and database owner", %{conn: conn} do
      valid_user_params = %{"roles" => ["inherit", "replication"], "username" => "a_new_user"}

      attrs = %{
        name: "with-user-owned-db",
        virtual_size: "small",
        num_instances: 5,
        database: %{
          name: "test",
          owner: "a_new_user"
        }
      }

      conn
      |> start(~p|/postgres/new|)
      |> click("button", "New User")
      |> submit_form("#user-form", %{"pg_user" => valid_user_params})
      |> assert_html(valid_user_params["username"])
      |> assert_html("inherit")
      |> assert_html("replication")
      |> submit_form("#cluster-form", cluster: attrs)

      cluster = Repo.get_by(Cluster, name: attrs.name)

      assert cluster.num_instances == 5
      assert cluster.database.name == "test"
      assert cluster.database.owner == "a_new_user"
    end

    test "can delete a user", %{conn: conn} do
      valid_user_params = %{"roles" => ["inherit", "replication"], "username" => "a_new_user"}

      conn
      |> start(~p|/postgres/new|)
      |> click("button", "New User")
      |> submit_form("#user-form", %{"pg_user" => valid_user_params})
      |> assert_html(valid_user_params["username"])
      |> click("#delete_user_#{valid_user_params["username"]}")
      |> submit_form("#cluster-form", @valid_attrs)

      cluster = Repo.get_by(Cluster, name: @valid_attrs.cluster.name)
      refute Enum.find(cluster.users, &(&1.roles == valid_user_params["roles"]))
    end

    test "can edit a user", %{conn: conn} do
      valid_user_params = %{"roles" => ["inherit", "replication"], "username" => "a_new_user"}
      updated_user_params = %{"roles" => ["login"], "username" => "a_new_user"}

      conn
      |> start(~p|/postgres/new|)
      |> click("button", "New User")
      |> submit_form("#user-form", %{"pg_user" => valid_user_params})
      |> assert_html(valid_user_params["username"])
      |> click("#edit_user_#{valid_user_params["username"]}")
      |> submit_form("#user-form", %{"pg_user" => updated_user_params})
      |> submit_form("#cluster-form", @valid_attrs)

      cluster = Repo.get_by(Cluster, name: @valid_attrs.cluster.name)
      assert Enum.find(cluster.users, &(&1.roles == updated_user_params["roles"]))
    end
  end

  describe "edit" do
    defp setup_edit(_) do
      namespace = resource_fixture(%{kind: "Namespace"})
      Runner.add(@kube_table_name, namespace)

      on_exit(fn ->
        Runner.delete(@kube_table_name, namespace)
      end)

      cluster = insert(:postgres_cluster, virtual_size: "small", num_instances: 1)

      %{namespace: namespace, cluster: cluster}
    end

    setup [:setup_edit]

    test "can edit an existing cluster", %{conn: conn, cluster: cluster} do
      conn
      |> start(~p"/postgres/#{cluster}/edit")
      |> submit_form("#cluster-form", @update_attrs)

      updated_cluster = Repo.get(Cluster, cluster.id)
      assert updated_cluster.num_instances == @update_attrs.cluster.num_instances
    end

    test "changing the virtual size field to custom exposes storage fields and defaults to the existing storage size", %{
      conn: conn,
      cluster: cluster
    } do
      {:ok, view, _html} = live(conn, ~p"/postgres/#{cluster}/edit")

      html =
        assert view
               |> element("#cluster-form")
               |> render_change(%{cluster: %{virtual_size: "custom"}})

      assert html =~ "Storage Class"
      assert html =~ CommonCore.Util.Memory.humanize(cluster.storage_size)
    end

    test "editing a cluster with a user", %{conn: conn} do
      valid_user_params = %{"roles" => ["login"], "username" => "my_user"}

      conn
      |> start(~p|/postgres/new|)
      |> click("button", "New User")
      |> submit_form("#user-form", %{"pg_user" => valid_user_params})
      |> assert_html(valid_user_params["username"])
      |> submit_form("#cluster-form", @valid_attrs)

      cluster = Repo.get_by(Cluster, name: @valid_attrs.cluster.name)

      updated_user_params = %{"roles" => ["login", "superuser"], "username" => "my_user"}

      conn
      |> start(~p"/postgres/#{cluster.id}/edit")
      |> click("#edit_user_#{valid_user_params["username"]}")
      |> submit_form("#user-form", %{"pg_user" => updated_user_params})
      |> submit_form("#cluster-form", Map.update(@valid_attrs, :cluster, %{}, fn attrs -> Map.delete(attrs, :name) end))

      updated_cluster = Repo.get(Cluster, cluster.id)

      # Ensure that the users password is not reset
      previous_user = Enum.find(cluster.password_versions, &(&1.username == updated_user_params["username"]))
      new_user = Enum.find(updated_cluster.password_versions, &(&1.username == updated_user_params["username"]))
      assert previous_user.password == new_user.password
    end
  end

  describe "postgres show page" do
    import ControlServer.Factory

    alias CommonCore.ResourceFactory
    alias CommonCore.Resources.Builder, as: B
    alias CommonCore.Resources.FieldAccessors

    @kube_table_name :default_state_table

    defp create_cluster(_) do
      cluster = insert(:postgres_cluster)

      # Add a pod that's owned by this cluster
      pod = :pod |> ResourceFactory.build() |> B.add_owner(cluster)

      Runner.add(@kube_table_name, pod)

      on_exit(fn ->
        Runner.delete(@kube_table_name, pod)
      end)

      %{cluster: cluster, pod: pod}
    end

    setup [:create_cluster]

    test "show cluster page", %{conn: conn, cluster: cluster} do
      conn
      |> start(~p"/postgres/#{cluster.id}/show")
      |> assert_html("Postgres Cluster: ")
      |> assert_html(cluster.name)
    end

    test "show cluster page with pod", %{conn: conn, cluster: cluster, pod: pod} do
      conn
      |> start(~p"/postgres/#{cluster.id}/pods")
      |> assert_html("Pods")
      |> assert_html(FieldAccessors.name(pod))
    end
  end
end
