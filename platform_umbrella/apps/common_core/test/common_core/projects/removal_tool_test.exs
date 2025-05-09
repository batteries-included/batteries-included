defmodule CommonCore.Projects.RemovalToolTest do
  use ExUnit.Case, async: true

  import CommonCore.Factory

  alias CommonCore.Projects.ProjectSnapshot
  alias CommonCore.Projects.RemovalTool

  describe "RemovalTool.remove/2" do
    test "can fields with no prefix" do
      struct = %{
        name: "test",
        age: 30,
        address: %{city: "New York", state: "NY"}
      }

      removals = [[:name], [:age]]

      expected_result = %{
        address: %{city: "New York", state: "NY"}
      }

      assert RemovalTool.remove(struct, removals) == expected_result
    end

    test "can remove indexes from an arry" do
      input = %{
        name: "test",
        age: 30,
        tags: ["tag1", "tag2", "tag3", "tag4"]
      }

      removals = [[:tags, 1], [:tags, 3]]

      # make sure that the list doesn't shift while removing them
      # and the the order is preserved
      expected_result = %{
        name: "test",
        age: 30,
        tags: ["tag1", "tag3"]
      }

      assert RemovalTool.remove(input, removals) == expected_result
    end

    test "doesn't change with no removals" do
      input = %{
        name: "test",
        age: 30,
        tags: ["tag1", "tag2", "tag3", "tag4"]
      }

      removals = []

      expected_result = %{
        name: "test",
        age: 30,
        tags: ["tag1", "tag2", "tag3", "tag4"]
      }

      assert RemovalTool.remove(input, removals) == expected_result
    end

    test "can remove from a ProjectSnapshot" do
      redis_0 =
        build(:redis)

      redis_1 =
        build(:redis)

      pg_cluster_0 =
        build(:postgres)

      pg_cluster_1 =
        build(:postgres)

      pg_cluster_2 =
        build(:postgres)

      traditional_service_0_env_vars = [
        build(:containers_env_value),
        build(:containers_env_value)
      ]

      traditional_service_0 =
        build(:traditional_service, env_values: traditional_service_0_env_vars)

      traditional_service_1_env_vars = [
        build(:containers_env_value),
        build(:containers_env_value)
      ]

      traditional_service_1 =
        build(:traditional_service, env_values: traditional_service_1_env_vars)

      traditional_service_2 =
        build(:traditional_service, env_values: [build(:containers_env_value), build(:containers_env_value)])

      input = %ProjectSnapshot{
        name: "test",
        description: "test",
        redis_instances: [
          redis_0,
          redis_1
        ],
        postgres_clusters: [
          pg_cluster_0,
          pg_cluster_1,
          pg_cluster_2
        ],
        traditional_services: [
          traditional_service_0,
          traditional_service_1,
          traditional_service_2
        ]
      }

      removals = [
        [:postgres_clusters, 1],
        [:traditional_services, 0, :env_values, 0],
        [:traditional_services, 1, :env_values, 1],
        [:traditional_services, 2]
      ]

      expected_result = %ProjectSnapshot{
        name: "test",
        description: "test",
        redis_instances: [
          redis_0,
          redis_1
        ],
        postgres_clusters: [
          pg_cluster_0,
          pg_cluster_2
        ],
        traditional_services: [
          %{traditional_service_0 | env_values: List.delete_at(traditional_service_0_env_vars, 0)},
          %{traditional_service_1 | env_values: List.delete_at(traditional_service_1_env_vars, 1)}
        ]
      }

      assert RemovalTool.remove(input, removals) == expected_result
    end
  end
end
