defmodule KubeServices.RoboSRE.DeleteResourceExecutorTest do
  use ExUnit.Case, async: false

  import Mox

  alias CommonCore.RoboSRE.Action
  alias KubeServices.MockKubeState
  alias KubeServices.MockResourceDeleter
  alias KubeServices.RoboSRE.DeleteResourceExecutor

  setup :verify_on_exit!

  describe "start_link/1" do
    test "starts the GenServer with default modules" do
      assert {:ok, pid} = DeleteResourceExecutor.start_link(name: :test_executor)
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "starts the GenServer with custom modules" do
      assert {:ok, pid} =
               DeleteResourceExecutor.start_link(
                 name: :test_executor_custom,
                 resource_deleter: MockResourceDeleter,
                 kube_state: MockKubeState
               )

      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "execute/1" do
    setup do
      # Start the GenServer with the default name so execute/1 can find it
      {:ok, pid} =
        DeleteResourceExecutor.start_link(
          resource_deleter: MockResourceDeleter,
          kube_state: MockKubeState
        )

      # Allow the GenServer to call the mocks
      allow(MockKubeState, self(), pid)
      allow(MockResourceDeleter, self(), pid)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{executor_pid: pid}
    end

    test "successfully deletes a resource when found" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :pod,
          "namespace" => "default",
          "name" => "test-pod"
        }
      }

      resource = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "test-pod", "namespace" => "default"}
      }

      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> {:ok, resource} end)

      expect(MockResourceDeleter, :delete, fn ^resource -> {:ok, %{"deleted" => true}} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, %{"deleted" => true}} = result
    end

    test "successfully deletes a resource with atom keys in params" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          api_version_kind: :deployment,
          namespace: "kube-system",
          name: "test-deployment"
        }
      }

      resource = %{
        "apiVersion" => "apps/v1",
        "kind" => "Deployment",
        "metadata" => %{"name" => "test-deployment", "namespace" => "kube-system"}
      }

      expect(MockKubeState, :get, fn :deployment, "kube-system", "test-deployment" -> {:ok, resource} end)

      expect(MockResourceDeleter, :delete, fn ^resource -> {:ok, %{"result" => "deleted"}} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, %{"result" => "deleted"}} = result
    end

    test "returns :not_found when resource is missing from kube state" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :service,
          "namespace" => "default",
          "name" => "missing-service"
        }
      }

      expect(MockKubeState, :get, fn :service, "default", "missing-service" -> :missing end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, :not_found} = result
    end

    test "returns :not_found when kube state returns {:error, :not_found}" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :configmap,
          "namespace" => "test-ns",
          "name" => "test-config"
        }
      }

      expect(MockKubeState, :get, fn :configmap, "test-ns", "test-config" -> {:error, :not_found} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, :not_found} = result
    end

    test "returns error when resource deletion fails" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :pod,
          "namespace" => "default",
          "name" => "protected-pod"
        }
      }

      resource = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "protected-pod", "namespace" => "default"}
      }

      expect(MockKubeState, :get, fn :pod, "default", "protected-pod" -> {:ok, resource} end)

      expect(MockResourceDeleter, :delete, fn ^resource -> {:error, :forbidden} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:error, :forbidden} = result
    end

    test "returns error when kube state returns unexpected error" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :secret,
          "namespace" => "default",
          "name" => "test-secret"
        }
      }

      expect(MockKubeState, :get, fn :secret, "default", "test-secret" -> {:error, :timeout} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:error, :timeout} = result
    end

    test "handles nil namespace correctly" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :clusterrole,
          "namespace" => nil,
          "name" => "cluster-admin"
        }
      }

      resource = %{
        "apiVersion" => "rbac.authorization.k8s.io/v1",
        "kind" => "ClusterRole",
        "metadata" => %{"name" => "cluster-admin"}
      }

      expect(MockKubeState, :get, fn :clusterrole, nil, "cluster-admin" -> {:ok, resource} end)

      expect(MockResourceDeleter, :delete, fn ^resource -> {:ok, %{"status" => "deleted"}} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, %{"status" => "deleted"}} = result
    end

    test "handles missing required parameters gracefully" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :pod
          # Missing namespace and name
        }
      }

      expect(MockKubeState, :get, fn :pod, nil, nil -> :missing end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, :not_found} = result
    end

    test "returns error for unsupported action type" do
      # Arrange
      action = %Action{
        action_type: :create_resource,
        params: %{
          "api_version_kind" => :pod,
          "namespace" => "default",
          "name" => "test-pod"
        }
      }

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:error, {:unsupported_action_type, :create_resource}} = result
    end

    test "works with mixed string and atom parameter keys" do
      # Arrange
      # This test verifies that the executor properly handles both string and atom keys
      # by falling back to string keys when atom keys are not found
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "namespace" => "production",
          "name" => "api-service",
          api_version_kind: :service
        }
      }

      resource = %{
        "apiVersion" => "v1",
        "kind" => "Service",
        "metadata" => %{"name" => "api-service", "namespace" => "production"}
      }

      expect(MockKubeState, :get, fn :service, "production", "api-service" -> {:ok, resource} end)

      expect(MockResourceDeleter, :delete, fn ^resource -> {:ok, %{"message" => "service deleted"}} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, %{"message" => "service deleted"}} = result
    end

    test "correctly converts string api_version_kind to atom when calling KubeState.get/3" do
      # Arrange - This tests the critical string-to-atom conversion for api_version_kind
      action = %Action{
        action_type: :delete_resource,
        params: %{
          # String value as it would come from PostgreSQL database
          "api_version_kind" => "pod",
          "namespace" => "default",
          "name" => "test-pod"
        }
      }

      resource = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "test-pod", "namespace" => "default"}
      }

      # Mock expects atom :pod, not string "pod" - this is the critical test
      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> {:ok, resource} end)
      expect(MockResourceDeleter, :delete, fn ^resource -> {:ok, %{"deleted" => true}} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, %{"deleted" => true}} = result
    end

    test "correctly converts various string api_version_kind formats to atoms" do
      # Test different resource kinds that come from database as strings
      test_cases = [
        {"deployment", :deployment, "apps/v1", "Deployment"},
        {"config_map", :config_map, "v1", "ConfigMap"},
        {"service_account", :service_account, "v1", "ServiceAccount"},
        {"persistent_volume_claim", :persistent_volume_claim, "v1", "PersistentVolumeClaim"},
        {"horizontal_pod_autoscaler", :horizontal_pod_autoscaler, "autoscaling/v2", "HorizontalPodAutoscaler"}
      ]

      for {string_kind, atom_kind, api_version, kind} <- test_cases do
        action = %Action{
          action_type: :delete_resource,
          params: %{
            # String from database
            "api_version_kind" => string_kind,
            "namespace" => "test-ns",
            "name" => "test-resource"
          }
        }

        resource = %{
          "apiVersion" => api_version,
          "kind" => kind,
          "metadata" => %{"name" => "test-resource", "namespace" => "test-ns"}
        }

        # Mock expects the converted atom, not the original string
        expect(MockKubeState, :get, fn ^atom_kind, "test-ns", "test-resource" -> {:ok, resource} end)
        expect(MockResourceDeleter, :delete, fn ^resource -> {:ok, %{"status" => "deleted"}} end)

        # Act
        result = DeleteResourceExecutor.execute(action)

        # Assert
        assert {:ok, %{"status" => "deleted"}} = result
      end
    end

    test "correctly converts string api_version_kind for cluster-scoped resources" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{
          # String from database
          "api_version_kind" => "cluster_role",
          "namespace" => nil,
          "name" => "test-cluster-role"
        }
      }

      resource = %{
        "apiVersion" => "rbac.authorization.k8s.io/v1",
        "kind" => "ClusterRole",
        "metadata" => %{"name" => "test-cluster-role"}
      }

      # Mock expects atom :cluster_role and nil namespace
      expect(MockKubeState, :get, fn :cluster_role, nil, "test-cluster-role" -> {:ok, resource} end)
      expect(MockResourceDeleter, :delete, fn ^resource -> {:ok, %{"deleted" => "cluster-role"}} end)

      # Act
      result = DeleteResourceExecutor.execute(action)

      # Assert
      assert {:ok, %{"deleted" => "cluster-role"}} = result
    end
  end

  describe "integration scenarios" do
    setup do
      # Start with unique name for integration tests to avoid conflicts
      {:ok, pid} =
        DeleteResourceExecutor.start_link(
          name: :integration_test_executor,
          resource_deleter: MockResourceDeleter,
          kube_state: MockKubeState
        )

      # Allow the GenServer to call the mocks
      allow(MockKubeState, self(), pid)
      allow(MockResourceDeleter, self(), pid)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{executor_pid: pid}
    end

    test "handles concurrent delete requests" do
      # Arrange
      action1 = %Action{
        action_type: :delete_resource,
        params: %{"api_version_kind" => :pod, "namespace" => "default", "name" => "pod-1"}
      }

      action2 = %Action{
        action_type: :delete_resource,
        params: %{"api_version_kind" => :pod, "namespace" => "default", "name" => "pod-2"}
      }

      resource1 = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "pod-1", "namespace" => "default"}
      }

      resource2 = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "pod-2", "namespace" => "default"}
      }

      MockKubeState
      |> expect(:get, fn :pod, "default", "pod-1" -> {:ok, resource1} end)
      |> expect(:get, fn :pod, "default", "pod-2" -> {:ok, resource2} end)

      MockResourceDeleter
      |> expect(:delete, fn ^resource1 -> {:ok, %{"deleted" => "pod-1"}} end)
      |> expect(:delete, fn ^resource2 -> {:ok, %{"deleted" => "pod-2"}} end)

      # Act
      task1 = Task.async(fn -> GenServer.call(:integration_test_executor, {:execute, action1}) end)
      task2 = Task.async(fn -> GenServer.call(:integration_test_executor, {:execute, action2}) end)

      result1 = Task.await(task1)
      result2 = Task.await(task2)

      # Assert
      assert {:ok, %{"deleted" => "pod-1"}} = result1
      assert {:ok, %{"deleted" => "pod-2"}} = result2
    end
  end
end
