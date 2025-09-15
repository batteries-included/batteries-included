defmodule KubeServices.RoboSRE.StuckKubeStateHandlerTest do
  use ExUnit.Case, async: false
  use ControlServer.DataCase

  alias CommonCore.RoboSRE.Issue
  alias KubeServices.RoboSRE.StuckKubeStateHandler

  describe "start_link/1" do
    test "starts the GenServer with default configuration" do
      assert {:ok, pid} = StuckKubeStateHandler.start_link(name: :test_handler)
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "starts the GenServer with custom name" do
      assert {:ok, pid} = StuckKubeStateHandler.start_link(name: :test_handler_custom)
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "preflight/1" do
    setup do
      # Start the GenServer with the default name so preflight/1 can find it
      {:ok, pid} = StuckKubeStateHandler.start_link()

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{handler_pid: pid}
    end

    test "returns ready for stuck_kubestate issue type" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "kubestate-stuck",
        issue_type: :stuck_kubestate,
        trigger_params: %{}
      }

      # Act
      result = StuckKubeStateHandler.preflight(issue)

      # Assert
      assert {:ok, :ready} = result
    end

    test "returns error for invalid issue type" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "some-other-issue",
        issue_type: :stale_resource,
        trigger_params: %{}
      }

      # Act
      result = StuckKubeStateHandler.preflight(issue)

      # Assert
      assert {:error, :invalid_issue_type} = result
    end

    test "returns error for unknown issue type" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "unknown-issue",
        issue_type: :unknown_type,
        trigger_params: %{}
      }

      # Act
      result = StuckKubeStateHandler.preflight(issue)

      # Assert
      assert {:error, :invalid_issue_type} = result
    end
  end

  describe "plan/1" do
    setup do
      # Start the GenServer with the default name so plan/1 can find it
      {:ok, pid} = StuckKubeStateHandler.start_link()

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{handler_pid: pid}
    end

    test "creates restart_kube_state plan for stuck_kubestate issue" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "kubestate-stuck",
        issue_type: :stuck_kubestate,
        trigger_params: %{}
      }

      # Act
      result = StuckKubeStateHandler.plan(issue)

      # Assert
      assert {:ok, plan} = result
      assert [action] = plan.actions
      assert action.action_type == :restart_kube_state
      assert action.params == %{}
      assert action.order_index == 0
    end

    test "returns error for unknown issue type" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "some-other-issue",
        issue_type: :stale_resource,
        trigger_params: %{}
      }

      # Act
      result = StuckKubeStateHandler.plan(issue)

      # Assert
      assert {:error, "Unknown issue type"} = result
    end
  end

  describe "verify/1" do
    setup do
      # Start the GenServer with the default name so verify/1 can find it
      {:ok, pid} = StuckKubeStateHandler.start_link()

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{handler_pid: pid}
    end

    test "always returns resolved for stuck_kubestate issue type" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "kubestate-stuck",
        issue_type: :stuck_kubestate,
        trigger_params: %{}
      }

      # Act
      result = StuckKubeStateHandler.verify(issue)

      # Assert
      assert {:ok, :resolved} = result
    end

    test "returns error for unknown issue type" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "some-other-issue",
        issue_type: :stale_resource,
        trigger_params: %{}
      }

      # Act
      result = StuckKubeStateHandler.verify(issue)

      # Assert
      assert {:error, "Unknown issue type"} = result
    end
  end

  describe "integration scenarios" do
    setup do
      # Start with unique name for integration tests to avoid conflicts
      {:ok, pid} = StuckKubeStateHandler.start_link(name: :integration_test_handler)

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
        subject: "kubestate-stuck",
        issue_type: :stuck_kubestate,
        trigger_params: %{}
      }

      # Act & Assert
      # 1. Preflight check
      preflight_result = GenServer.call(:integration_test_handler, {:preflight, issue})
      assert {:ok, :ready} = preflight_result

      # 2. Plan creation
      plan_result = GenServer.call(:integration_test_handler, {:plan, issue})
      assert {:ok, plan} = plan_result
      assert [action] = plan.actions
      assert action.action_type == :restart_kube_state

      # 3. Verification
      verify_result = GenServer.call(:integration_test_handler, {:verify, issue})
      assert {:ok, :resolved} = verify_result
    end

    test "handles concurrent requests" do
      # Arrange
      issue1 = %Issue{
        id: "test-issue-1",
        subject: "kubestate-stuck-1",
        issue_type: :stuck_kubestate,
        trigger_params: %{}
      }

      issue2 = %Issue{
        id: "test-issue-2",
        subject: "kubestate-stuck-2",
        issue_type: :stuck_kubestate,
        trigger_params: %{}
      }

      # Act
      task1 = Task.async(fn -> GenServer.call(:integration_test_handler, {:preflight, issue1}) end)
      task2 = Task.async(fn -> GenServer.call(:integration_test_handler, {:preflight, issue2}) end)

      result1 = Task.await(task1)
      result2 = Task.await(task2)

      # Assert
      assert {:ok, :ready} = result1
      assert {:ok, :ready} = result2
    end

    test "handles mixed operations concurrently" do
      # Arrange
      issue = %Issue{
        id: "test-issue-id",
        subject: "kubestate-stuck",
        issue_type: :stuck_kubestate,
        trigger_params: %{}
      }

      # Act - Run preflight, plan, and verify concurrently
      task1 = Task.async(fn -> GenServer.call(:integration_test_handler, {:preflight, issue}) end)
      task2 = Task.async(fn -> GenServer.call(:integration_test_handler, {:plan, issue}) end)
      task3 = Task.async(fn -> GenServer.call(:integration_test_handler, {:verify, issue}) end)

      result1 = Task.await(task1)
      result2 = Task.await(task2)
      result3 = Task.await(task3)

      # Assert
      assert {:ok, :ready} = result1
      assert {:ok, _plan} = result2
      assert {:ok, :resolved} = result3
    end

    test "handles invalid issue types gracefully in concurrent scenario" do
      # Arrange
      valid_issue = %Issue{
        id: "test-issue-valid",
        subject: "kubestate-stuck",
        issue_type: :stuck_kubestate,
        trigger_params: %{}
      }

      invalid_issue = %Issue{
        id: "test-issue-invalid",
        subject: "some-other-issue",
        issue_type: :stale_resource,
        trigger_params: %{}
      }

      # Act
      task1 = Task.async(fn -> GenServer.call(:integration_test_handler, {:preflight, valid_issue}) end)
      task2 = Task.async(fn -> GenServer.call(:integration_test_handler, {:preflight, invalid_issue}) end)

      result1 = Task.await(task1)
      result2 = Task.await(task2)

      # Assert
      assert {:ok, :ready} = result1
      assert {:error, :invalid_issue_type} = result2
    end
  end

  describe "error handling" do
    setup do
      {:ok, pid} = StuckKubeStateHandler.start_link(name: :error_test_handler)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{handler_pid: pid}
    end

    test "handles malformed issue structs gracefully" do
      # This test ensures the handler doesn't crash on unexpected input
      malformed_issues = [
        %Issue{id: nil, subject: nil, issue_type: :stuck_kubestate, trigger_params: nil},
        %Issue{id: "", subject: "", issue_type: :stuck_kubestate, trigger_params: %{}},
        %Issue{id: "test", subject: "test", issue_type: nil, trigger_params: %{}}
      ]

      for issue <- malformed_issues do
        # These should not crash the GenServer
        preflight_result = GenServer.call(:error_test_handler, {:preflight, issue})
        plan_result = GenServer.call(:error_test_handler, {:plan, issue})
        verify_result = GenServer.call(:error_test_handler, {:verify, issue})

        # The handler should handle these gracefully
        case issue.issue_type do
          :stuck_kubestate ->
            assert {:ok, :ready} = preflight_result
            assert {:ok, _plan} = plan_result
            assert {:ok, :resolved} = verify_result

          _ ->
            assert {:error, :invalid_issue_type} = preflight_result
            assert {:error, "Unknown issue type"} = plan_result
            assert {:error, "Unknown issue type"} = verify_result
        end
      end
    end
  end
end
