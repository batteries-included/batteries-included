defmodule ControlServer.RedisTest do
  use ControlServer.DataCase

  alias CommonCore.Redis.RedisInstance
  alias ControlServer.Redis

  describe "redis_instances" do
    import ControlServer.RedisFixtures

    @invalid_attrs %{
      name: "111111111111____",
      num_instances: nil
    }

    test "list_redis_instances/0 returns all failover clusters" do
      redis_instance = redis_instance_fixture()
      assert Redis.list_redis_instances() == [redis_instance]
    end

    test "list_redis_instances/1 returns paginated failover clusters" do
      pagination_test(&redis_instance_fixture/1, &Redis.list_redis_instances/1)
    end

    test "get_redis_instance!/1 returns the redis_instance with given id" do
      redis_instance = redis_instance_fixture()
      assert Redis.get_redis_instance!(redis_instance.id) == redis_instance
    end

    test "create_redis_instance/1 with valid data creates a redis_instance" do
      valid_attrs = %{
        memory_request: "some memory_request",
        name: "some-name",
        num_instances: 42
      }

      assert {:ok, %RedisInstance{} = redis_instance} = Redis.create_redis_instance(valid_attrs)

      assert redis_instance.name == "some-name"
      assert redis_instance.num_instances == 42
    end

    test "create_redis_instance/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Redis.create_redis_instance(@invalid_attrs)
    end

    test "update_redis_instance/2 with valid data updates the redis_instance" do
      redis_instance = redis_instance_fixture()

      update_attrs = %{
        num_instances: 43
      }

      assert {:ok, %RedisInstance{} = redis_instance} = Redis.update_redis_instance(redis_instance, update_attrs)

      assert redis_instance.num_instances == 43
    end

    test "update_redis_instance/2 with invalid data returns error changeset" do
      redis_instance = redis_instance_fixture()

      assert {:error, %Ecto.Changeset{}} = Redis.update_redis_instance(redis_instance, @invalid_attrs)

      assert redis_instance == Redis.get_redis_instance!(redis_instance.id)
    end

    test "delete_redis_instance/1 deletes the redis_instance" do
      redis_instance = redis_instance_fixture()
      assert {:ok, %RedisInstance{}} = Redis.delete_redis_instance(redis_instance)
      assert_raise Ecto.NoResultsError, fn -> Redis.get_redis_instance!(redis_instance.id) end
    end

    test "change_redis_instance/1 returns a redis_instance changeset" do
      redis_instance = redis_instance_fixture()
      assert %Ecto.Changeset{} = Redis.change_redis_instance(redis_instance)
    end
  end
end
