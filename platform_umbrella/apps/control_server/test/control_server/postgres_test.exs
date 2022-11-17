defmodule ControlServer.PostgresTest do
  use ControlServer.DataCase

  alias ControlServer.Postgres

  describe "clusters" do
    alias ControlServer.Postgres.Cluster
    alias ControlServer.Postgres.PGUser

    @valid_attrs %{
      name: "some name",
      num_instances: 2,
      postgres_version: "12.1",
      storage_size: "500Mi",
      users: [%{username: "userone", roles: ["superuser"]}],
      databases: [%{name: "maindata", owner: "userone"}]
    }
    @update_attrs %{
      name: "some updated name",
      num_instances: 3,
      postgres_version: "13",
      storage_size: "250Mi",
      users: [
        %{username: "userone", roles: ["superuser"]},
        %{username: "usertwo", roles: ["nologin"]}
      ],
      databases: [%{name: "maindata", owner: "userone"}, %{name: "testdata", owner: "usertwo"}]
    }
    @invalid_attrs %{name: nil, num_instances: nil, postgres_version: nil, size: nil}

    def cluster_fixture(attrs \\ %{}) do
      {:ok, cluster} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Postgres.create_cluster()

      cluster
    end

    test "list_clusters/0 returns all clusters" do
      cluster = cluster_fixture()
      assert Postgres.list_clusters() == [cluster]
    end

    test "get_cluster!/1 returns the cluster with given id" do
      cluster = cluster_fixture()
      assert Postgres.get_cluster!(cluster.id) == cluster
    end

    test "create_cluster/1 with valid data creates a cluster" do
      assert {:ok, %Cluster{} = cluster} = Postgres.create_cluster(@valid_attrs)
      assert cluster.name == "some name"
      assert cluster.num_instances == 2
      assert cluster.postgres_version == "12.1"
      assert cluster.storage_size == "500Mi"
      assert cluster.users == [%PGUser{username: "userone", roles: ["superuser"]}]
    end

    test "create_cluster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Postgres.create_cluster(@invalid_attrs)
    end

    test "update_cluster/2 with valid data updates the cluster" do
      cluster = cluster_fixture()
      assert {:ok, %Cluster{} = cluster} = Postgres.update_cluster(cluster, @update_attrs)
      assert cluster.name == "some updated name"
      assert cluster.num_instances == 3
      assert cluster.postgres_version == "13"
      assert cluster.storage_size == "250Mi"
    end

    test "update_cluster/2 with invalid data returns error changeset" do
      cluster = cluster_fixture()
      assert {:error, %Ecto.Changeset{}} = Postgres.update_cluster(cluster, @invalid_attrs)
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
      cluster = KubeExt.Defaults.GiteaDB.gitea_cluster()
      assert {result, _db_res} = Postgres.find_or_create(cluster)
      assert :ok == result
    end

    test "find_or_create with reasonable Battery defaults" do
      cluster = KubeExt.Defaults.ControlDB.control_cluster()

      assert {result, _db_res} = Postgres.find_or_create(cluster)
      assert :ok == result
    end
  end
end
