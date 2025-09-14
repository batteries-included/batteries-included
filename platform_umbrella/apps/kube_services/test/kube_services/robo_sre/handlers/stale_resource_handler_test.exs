defmodule KubeServices.RoboSRE.StaleResourceHandlerTest do
  use ExUnit.Case, async: false
  use ControlServer.DataCase

  import Mox

  alias CommonCore.RoboSRE.Issue
  alias KubeServices.MockKubeState
  alias KubeServices.MockStale
  alias KubeServices.RoboSRE.StaleResourceHandler

  setup :verify_on_exit!

  describe "start_link/1" do
    test "starts the GenServer with default modules" do
      assert {:ok, pid} = StaleResourceHandler.start_link(name: :test_handler)
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "starts the GenServer with custom modules" do
      assert {:ok, pid} =
               StaleResourceHandler.start_link(
                 name: :test_handler_custom,
                 kube_state: MockKubeState,
                 stale: MockStale
               )

      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "preflight/1" do
    setup do
      # Start the GenServer with the default name so preflight/1 can find it
      {:ok, pid} =
        StaleResourceHandler.start_link(
          kube_state: MockKubeState,
          stale: MockStale
        )

      # Allow the GenServer to call the mocks
      allow(MockKubeState, self(), pid)
      allow(MockStale, self(), pid)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{handler_pid: pid}
    end

    test "returns ready when resource is stale" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "default:test-pod",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      resource = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "test-pod", "namespace" => "default"}
      }

      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> {:ok, resource} end)
      expect(MockStale, :stale?, fn ^resource -> true end)

      # Act
      result = StaleResourceHandler.preflight(issue)

      # Assert
      assert {:ok, :ready} = result
    end

    test "returns skip when resource is missing" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "default:test-pod",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> :missing end)

      # Act
      result = StaleResourceHandler.preflight(issue)

      # Assert
      assert {:ok, :skip} = result
    end

    test "returns error when resource is not stale" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "default:test-pod",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      resource = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "test-pod", "namespace" => "default"}
      }

      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> {:ok, resource} end)
      expect(MockStale, :stale?, fn ^resource -> false end)

      # Act
      result = StaleResourceHandler.preflight(issue)

      # Assert
      assert {:error, :not_stale} = result
    end

    test "handles atom keys in trigger_params" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "kube-system:test-deployment",
        issue_type: :stale_resource,
        trigger_params: %{api_version_kind: :deployment}
      }

      resource = %{
        "apiVersion" => "apps/v1",
        "kind" => "Deployment",
        "metadata" => %{"name" => "test-deployment", "namespace" => "kube-system"}
      }

      expect(MockKubeState, :get, fn :deployment, "kube-system", "test-deployment" -> {:ok, resource} end)
      expect(MockStale, :stale?, fn ^resource -> true end)

      # Act
      result = StaleResourceHandler.preflight(issue)

      # Assert
      assert {:ok, :ready} = result
    end

    test "handles cluster-scoped resources (no namespace)" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "test-cluster-role",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "cluster_role"}
      }

      resource = %{
        "apiVersion" => "rbac.authorization.k8s.io/v1",
        "kind" => "ClusterRole",
        "metadata" => %{"name" => "test-cluster-role"}
      }

      expect(MockKubeState, :get, fn :cluster_role, nil, "test-cluster-role" -> {:ok, resource} end)
      expect(MockStale, :stale?, fn ^resource -> true end)

      # Act
      result = StaleResourceHandler.preflight(issue)

      # Assert
      assert {:ok, :ready} = result
    end
  end

  describe "plan/1" do
    setup do
      # Start the GenServer with the default name so plan/1 can find it
      {:ok, pid} =
        StaleResourceHandler.start_link(
          kube_state: MockKubeState,
          stale: MockStale
        )

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{handler_pid: pid}
    end

    test "creates delete resource plan for stale resource issue" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "default:test-pod",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      # Act
      result = StaleResourceHandler.plan(issue)

      # Assert
      assert {:ok, plan} = result
      assert [action] = plan.actions
      assert action.action_type == :delete_resource
      assert action.params.api_version_kind == :pod
      assert action.params.namespace == "default"
      assert action.params.name == "test-pod"
    end

    test "handles cluster-scoped resources in plan" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "test-cluster-role",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "cluster_role"}
      }

      # Act
      result = StaleResourceHandler.plan(issue)

      # Assert
      assert {:ok, plan} = result
      assert [action] = plan.actions
      assert action.action_type == :delete_resource
      assert action.params.api_version_kind == :cluster_role
      assert action.params.namespace == nil
      assert action.params.name == "test-cluster-role"
    end

    test "returns error for unknown issue type" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "test-subject",
        issue_type: :unknown_type,
        trigger_params: %{}
      }

      # Act
      result = StaleResourceHandler.plan(issue)

      # Assert
      assert {:error, "Unknown issue type"} = result
    end
  end

  describe "verify/1" do
    setup do
      # Start the GenServer with the default name so verify/1 can find it
      {:ok, pid} =
        StaleResourceHandler.start_link(
          kube_state: MockKubeState,
          stale: MockStale
        )

      # Allow the GenServer to call the mocks
      allow(MockKubeState, self(), pid)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{handler_pid: pid}
    end

    test "returns resolved when resource is missing" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "default:test-pod",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> :missing end)

      # Act
      result = StaleResourceHandler.verify(issue)

      # Assert
      assert {:ok, :resolved} = result
    end

    test "returns pending when resource still exists" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "default:test-pod",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      resource = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "test-pod", "namespace" => "default"}
      }

      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> {:ok, resource} end)

      # Act
      result = StaleResourceHandler.verify(issue)

      # Assert
      assert {:ok, :pending} = result
    end

    test "returns error for unknown issue type" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "test-subject",
        issue_type: :unknown_type,
        trigger_params: %{}
      }

      # Act
      result = StaleResourceHandler.verify(issue)

      # Assert
      assert {:error, "Unknown issue type"} = result
    end
  end

  describe "integration scenarios" do
    setup do
      # Start with unique name for integration tests to avoid conflicts
      {:ok, pid} =
        StaleResourceHandler.start_link(
          name: :integration_test_handler,
          kube_state: MockKubeState,
          stale: MockStale
        )

      # Allow the GenServer to call the mocks
      allow(MockKubeState, self(), pid)
      allow(MockStale, self(), pid)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{handler_pid: pid}
    end

    test "handles full workflow: preflight -> plan -> verify" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "default:test-pod",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      resource = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "test-pod", "namespace" => "default"}
      }

      # Preflight: resource exists and is stale
      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> {:ok, resource} end)
      expect(MockStale, :stale?, fn ^resource -> true end)

      # Verify: resource has been deleted
      expect(MockKubeState, :get, fn :pod, "default", "test-pod" -> :missing end)

      # Act & Assert
      # 1. Preflight check
      preflight_result = GenServer.call(:integration_test_handler, {:preflight, issue})
      assert {:ok, :ready} = preflight_result

      # 2. Plan creation
      plan_result = GenServer.call(:integration_test_handler, {:plan, issue})
      assert {:ok, plan} = plan_result
      assert [action] = plan.actions
      assert action.action_type == :delete_resource

      # 3. Verification
      verify_result = GenServer.call(:integration_test_handler, {:verify, issue})
      assert {:ok, :resolved} = verify_result
    end

    test "handles concurrent requests" do
      # Arrange
      issue1 = %Issue{
        id: "test-issue-1",
        subject: "default:test-pod-1",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      issue2 = %Issue{
        id: "test-issue-2",
        subject: "default:test-pod-2",
        issue_type: :stale_resource,
        trigger_params: %{"api_version_kind" => "pod"}
      }

      resource1 = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "test-pod-1", "namespace" => "default"}
      }

      resource2 = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "test-pod-2", "namespace" => "default"}
      }

      MockKubeState
      |> expect(:get, fn :pod, "default", "test-pod-1" -> {:ok, resource1} end)
      |> expect(:get, fn :pod, "default", "test-pod-2" -> {:ok, resource2} end)

      MockStale
      |> expect(:stale?, fn ^resource1 -> true end)
      |> expect(:stale?, fn ^resource2 -> true end)

      # Act
      task1 = Task.async(fn -> GenServer.call(:integration_test_handler, {:preflight, issue1}) end)
      task2 = Task.async(fn -> GenServer.call(:integration_test_handler, {:preflight, issue2}) end)

      result1 = Task.await(task1)
      result2 = Task.await(task2)

      # Assert
      assert {:ok, :ready} = result1
      assert {:ok, :ready} = result2
    end
  end
end
