defmodule ControlServer.PostgresTest do
  use ControlServer.DataCase

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGUser
  alias ControlServer.Postgres

  describe "clusters" do
    @valid_attrs %{
      name: "some-name",
      num_instances: 2,
      storage_size: 209_715_200,
      users: [%{username: "userone", roles: ["superuser"]}],
      database: %{name: "maindata", owner: "userone"}
    }
    @update_attrs %{
      num_instances: 3,
      storage_size: 524_288_000,
      users: [
        %{username: "userone", roles: ["superuser"]},
        %{username: "usertwo", roles: ["nologin"]}
      ],
      database: %{name: "maindata", owner: "userone"}
    }
    @invalid_attrs %{name: nil, num_instances: nil, size: nil}

    def cluster_fixture(attrs \\ %{}) do
      {:ok, cluster} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Postgres.create_cluster()

      cluster
      |> Map.put(:virtual_size, nil)
      |> Map.put(:virtual_storage_size_range_value, nil)
    end

    test "list_clusters/0 returns all clusters" do
      cluster = cluster_fixture()
      assert Postgres.list_clusters() == [cluster]
    end

    # create a number of clusters with a unique name pattern
    # find clusters matching that pattern 1 at a time
    # ensure we can fetch e.g. first and last "page"
    test "list_clusters/1 returns paginated clusters" do
      name_prefix = "list-clusters-pagination-test"
      params = %{order_by: [:id], filters: [%{field: :name, op: :ilike, value: "#{name_prefix}-"}]}
      created = Enum.map(0..9, fn i -> cluster_fixture(%{name: "#{name_prefix}-#{i}"}) end)

      assert {:ok, {[first], meta}} = Postgres.list_clusters(Map.put(params, :first, 1))
      assert created |> List.first() |> Map.get(:id) == first.id
      assert {false, true} = {meta.has_previous_page?, meta.has_next_page?}

      assert {:ok, {[last], meta}} = Postgres.list_clusters(Map.put(params, :last, 1))
      assert created |> List.last() |> Map.get(:id) == last.id
      assert {true, false} = {meta.has_previous_page?, meta.has_next_page?}
    end

    test "get_cluster!/1 returns the cluster with given id" do
      cluster = cluster_fixture()
      assert Postgres.get_cluster!(cluster.id) == cluster
    end

    test "create_cluster/1 with valid data creates a cluster" do
      assert {:ok, %Cluster{} = cluster} = Postgres.create_cluster(@valid_attrs)
      assert cluster.name == "some-name"
      assert cluster.num_instances == 2
      assert cluster.storage_size == 209_715_200
      assert [%PGUser{username: "userone", roles: ["superuser"]}] = cluster.users
    end

    test "create_cluster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Postgres.create_cluster(@invalid_attrs)
    end

    test "update_cluster/2 with valid data updates the cluster" do
      cluster = cluster_fixture()
      assert {:ok, %Cluster{} = cluster} = Postgres.update_cluster(cluster, @update_attrs)
      assert cluster.num_instances == 3
      assert cluster.storage_size == 524_288_000
    end

    test "update_cluster/2 with invalid data returns error changeset" do
      cluster = cluster_fixture()
      assert {:error, %Ecto.Changeset{}} = Postgres.update_cluster(cluster, @invalid_attrs)
      assert cluster == Postgres.get_cluster!(cluster.id)
    end

    test "update_cluster/2 with decreased storage size returns error changeset" do
      cluster = cluster_fixture()
      assert {:error, changeset} = Postgres.update_cluster(cluster, %{storage_size: 1})
      assert "can't decrease storage size from 200MB" in errors_on(changeset).storage_size
      assert cluster == Postgres.get_cluster!(cluster.id)
    end

    test "delete_cluster/1 deletes the cluster" do
      cluster = cluster_fixture()
      assert {:ok, %Cluster{}} = Postgres.delete_cluster(cluster)
      assert_raise Ecto.NoResultsError, fn -> Postgres.get_cluster!(cluster.id) end
    end

    test "change_cluster/1 returns a cluster changeset" do
      cluster = cluster_fixture()
      assert %Ecto.Changeset{} = Postgres.change_cluster(cluster)
    end

    test "find_or_create with reasonable defaults" do
      cluster = CommonCore.Defaults.ForgejoDB.forgejo_cluster()
      assert {result, _db_res} = Postgres.find_or_create(cluster)
      assert :ok == result
    end

    test "find_or_create with reasonable Battery defaults" do
      cluster = CommonCore.Defaults.ControlDB.control_cluster()

      assert {result, _db_res} = Postgres.find_or_create(cluster)
      assert :ok == result
    end
  end
end
