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
          kube_state: MockKubeState,
          name: KubeServices.RoboSRE.DeleteResourceExecutorTest.Executor
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

    test "successfully deletes a resource when found", %{executor_pid: pid} do
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

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, %{"deleted" => true}} = result
    end

    test "successfully deletes a resource with atom keys in params", %{executor_pid: pid} do
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

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, %{"result" => "deleted"}} = result
    end

    test "returns :not_found when resource is missing from kube state", %{executor_pid: pid} do
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :service,
          "namespace" => "default",
          "name" => "missing-service"
        }
      }

      expect(MockKubeState, :get, fn :service, "default", "missing-service" -> :missing end)

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, :not_found} = result
    end

    test "returns :not_found when kube state returns {:error, :not_found}", %{executor_pid: pid} do
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :configmap,
          "namespace" => "test-ns",
          "name" => "test-config"
        }
      }

      expect(MockKubeState, :get, fn :configmap, "test-ns", "test-config" -> {:error, :not_found} end)

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, :not_found} = result
    end

    test "returns error when resource deletion fails", %{executor_pid: pid} do
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

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:error, :forbidden} = result
    end

    test "returns error when kube state returns unexpected error", %{executor_pid: pid} do
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :secret,
          "namespace" => "default",
          "name" => "test-secret"
        }
      }

      expect(MockKubeState, :get, fn :secret, "default", "test-secret" -> {:error, :timeout} end)

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:error, :timeout} = result
    end

    test "handles nil namespace correctly", %{executor_pid: pid} do
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

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, %{"status" => "deleted"}} = result
    end

    test "handles missing required parameters gracefully", %{executor_pid: pid} do
      action = %Action{
        action_type: :delete_resource,
        params: %{
          "api_version_kind" => :pod
          # Missing namespace and name
        }
      }

      expect(MockKubeState, :get, fn :pod, nil, nil -> :missing end)

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, :not_found} = result
    end

    test "returns error for unsupported action type", %{executor_pid: pid} do
      action = %Action{
        action_type: :create_resource,
        params: %{
          "api_version_kind" => :pod,
          "namespace" => "default",
          "name" => "test-pod"
        }
      }

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:error, {:unsupported_action_type, :create_resource}} = result
    end

    test "works with mixed string and atom parameter keys", %{executor_pid: pid} do
      # Arran
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

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, %{"message" => "service deleted"}} = result
    end

    test "correctly converts string api_version_kind to atom when calling KubeState.get/3", %{executor_pid: pid} do
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

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, %{"deleted" => true}} = result
    end

    test "correctly converts string api_version_kind for cluster-scoped resources", %{executor_pid: pid} do
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

      result = DeleteResourceExecutor.execute(pid, action)

      assert {:ok, %{"deleted" => "cluster-role"}} = result
    end
  end
end
