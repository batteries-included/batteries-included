defmodule ControlServer.RedisTest do
  use ControlServer.DataCase

  alias CommonCore.Redis.FailoverCluster
  alias ControlServer.Redis

  describe "failover_clusters" do
    import ControlServer.RedisFixtures

    @invalid_attrs %{
      name: "111111111111____",
      num_redis_instances: nil,
      num_sentinel_instances: nil
    }

    test "list_failover_clusters/0 returns all failover_clusters" do
      failover_cluster = failover_cluster_fixture()
      assert Redis.list_failover_clusters() == [failover_cluster]
    end

    test "get_failover_cluster!/1 returns the failover_cluster with given id" do
      failover_cluster = failover_cluster_fixture()
      assert Redis.get_failover_cluster!(failover_cluster.id) == failover_cluster
    end

    test "create_failover_cluster/1 with valid data creates a failover_cluster" do
      valid_attrs = %{
        memory_request: "some memory_request",
        name: "some-name",
        num_redis_instances: 42,
        num_sentinel_instances: 42
      }

      assert {:ok, %FailoverCluster{} = failover_cluster} = Redis.create_failover_cluster(valid_attrs)

      assert failover_cluster.name == "some-name"
      assert failover_cluster.num_redis_instances == 42
      assert failover_cluster.num_sentinel_instances == 42
    end

    test "create_failover_cluster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Redis.create_failover_cluster(@invalid_attrs)
    end

    test "update_failover_cluster/2 with valid data updates the failover_cluster" do
      failover_cluster = failover_cluster_fixture()

      update_attrs = %{
        name: "some-updated-name",
        num_redis_instances: 43,
        num_sentinel_instances: 43
      }

      assert {:ok, %FailoverCluster{} = failover_cluster} = Redis.update_failover_cluster(failover_cluster, update_attrs)

      assert failover_cluster.name == "some-updated-name"
      assert failover_cluster.num_redis_instances == 43
      assert failover_cluster.num_sentinel_instances == 43
    end

    test "update_failover_cluster/2 with invalid data returns error changeset" do
      failover_cluster = failover_cluster_fixture()

      assert {:error, %Ecto.Changeset{}} = Redis.update_failover_cluster(failover_cluster, @invalid_attrs)

      assert failover_cluster == Redis.get_failover_cluster!(failover_cluster.id)
    end

    test "delete_failover_cluster/1 deletes the failover_cluster" do
      failover_cluster = failover_cluster_fixture()
      assert {:ok, %FailoverCluster{}} = Redis.delete_failover_cluster(failover_cluster)
      assert_raise Ecto.NoResultsError, fn -> Redis.get_failover_cluster!(failover_cluster.id) end
    end

    test "change_failover_cluster/1 returns a failover_cluster changeset" do
      failover_cluster = failover_cluster_fixture()
      assert %Ecto.Changeset{} = Redis.change_failover_cluster(failover_cluster)
    end
  end
end
