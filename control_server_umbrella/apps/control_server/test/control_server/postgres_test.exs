defmodule ControlServer.PostgresTest do
  use ControlServer.DataCase

  alias ControlServer.Postgres

  describe "clusters" do
    alias ControlServer.Postgres.Cluster

    @valid_attrs %{
      name: "some name",
      num_instances: 42,
      postgres_version: "some postgres_version",
      size: "some size"
    }
    @update_attrs %{
      name: "some updated name",
      num_instances: 43,
      postgres_version: "some updated postgres_version",
      size: "some updated size"
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
      assert cluster.num_instances == 42
      assert cluster.postgres_version == "some postgres_version"
      assert cluster.size == "some size"
    end

    test "create_cluster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Postgres.create_cluster(@invalid_attrs)
    end

    test "update_cluster/2 with valid data updates the cluster" do
      cluster = cluster_fixture()
      assert {:ok, %Cluster{} = cluster} = Postgres.update_cluster(cluster, @update_attrs)
      assert cluster.name == "some updated name"
      assert cluster.num_instances == 43
      assert cluster.postgres_version == "some updated postgres_version"
      assert cluster.size == "some updated size"
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
  end
end
