defmodule KubeServices.RoboSRE.IssueWorkerTest do
  @moduledoc """
  Tests for IssueWorker GenServer that manages the lifecycle of a single RoboSRE issue.

  This test suite serves as documentation for how the IssueWorker handles issues
  through their complete lifecycle:
  - Analysis phase: running analyzers to determine context
  - Remediation phase: executing handlers to fix the issue
  - Monitoring phase: checking if remediation was successful
  - State persistence: keeping issue state in sync with database

  The worker follows the state machine pattern defined in the RoboSRE documentation.
  """
  use ExUnit.Case, async: false
  use ControlServer.DataCase

  import ControlServer.Factory
  import Mox

  alias CommonCore.RoboSRE.RemediationPlan
  alias ControlServer.RoboSRE.Issues
  alias ControlServer.RoboSRE.RemediationPlans
  alias EventCenter.Database, as: DatabaseEventCenter
  alias KubeServices.RoboSRE.IssueWorker
  alias KubeServices.RoboSRE.MockDeleteResourceExecutor
  alias KubeServices.RoboSRE.MockStaleResourceHandler

  setup :verify_on_exit!
  setup :set_mox_from_context

  describe "IssueWorker lifecycle" do
    setup do
      # Start the Registry for IssueWorker process naming
      {:ok, registry_pid} = start_supervised({Registry, keys: :unique, name: KubeServices.RoboSRE.Registry})

      # Subscribe to issue database events so we can wait for state changes
      :ok = DatabaseEventCenter.subscribe(:issue)

      # Create an issue in the database for the worker to process
      issue =
        insert(:issue, %{
          subject: "test-cluster.pod.test-app.container",
          issue_type: :stale_resource,
          trigger: :kubernetes_event,
          handler: :stale_resource,
          status: :detected,
          trigger_params: %{
            "api_version_kind" => "pod",
            "namespace" => "default",
            "name" => "test-pod"
          }
        })

      %{issue: issue, registry_pid: registry_pid}
    end

    defp wait_for_issue_status(issue_id, expected_status, timeout \\ 5000) do
      receive do
        {:update, %{id: ^issue_id, status: ^expected_status}} ->
          :ok

        {:update, %{id: ^issue_id}} ->
          # Got an update for our issue but not the status we want, keep waiting
          wait_for_issue_status(issue_id, expected_status, timeout)

        _ ->
          # Got some other message, keep waiting
          wait_for_issue_status(issue_id, expected_status, timeout)
      after
        timeout ->
          # Fetch current status for debugging
          current_issue = Issues.get_issue!(issue_id)
          {:error, {:timeout, expected_status, current_issue.status}}
      end
    end

    defp assert_worker_stopped(issue_id) do
      # Check that no worker process is running for this issue
      case Registry.lookup(KubeServices.RoboSRE.Registry, issue_id) do
        [] ->
          # No process registered, good!
          :ok

        [{pid, _}] ->
          if Process.alive?(pid) do
            flunk("Worker process #{inspect(pid)} is still alive for issue #{issue_id}")
          else
            # Process exists in registry but is dead, registry cleanup may be delayed
            :ok
          end
      end
    end

    test "processes stale resource issue through complete happy path", %{issue: issue} do
      # Mock the handler to simulate successful preflight, plan, and verify
      plan_template =
        :pod
        |> RemediationPlan.delete_resource("default", "test-pod")
        |> Map.put(:success_delay_ms, 500)
        |> Map.put(:retry_delay_ms, 100)

      # Allow the mocks to be called multiple times since worker might restart
      stub(MockStaleResourceHandler, :preflight, fn _issue -> {:ok, :ready} end)
      stub(MockStaleResourceHandler, :plan, fn _issue -> {:ok, plan_template} end)
      stub(MockStaleResourceHandler, :verify, fn _issue -> {:ok, :resolved} end)
      stub(MockDeleteResourceExecutor, :execute, fn _action -> {:ok, %{"deleted" => true}} end)

      # Start the worker manually (not supervised) so it can stop normally without restart
      {:ok, worker_pid} =
        IssueWorker.start_link(
          issue: issue,
          # Slightly longer to avoid race conditions
          analysis_delay_ms: 50,
          stale_resource_handler: MockStaleResourceHandler,
          delete_resource_executor: MockDeleteResourceExecutor
        )

      # Allow the worker to call our mocks
      allow(MockStaleResourceHandler, self(), worker_pid)
      allow(MockDeleteResourceExecutor, self(), worker_pid)

      # Wait for the issue to transition to resolved status using database events
      case wait_for_issue_status(issue.id, :resolved) do
        :ok ->
          :ok

        {:error, {:timeout, expected, actual}} ->
          flunk("Timeout waiting for issue to reach #{expected}, currently #{actual}")
      end

      # Verify the issue moved through the expected states and ended as resolved
      updated_issue = Issues.get_issue!(issue.id)
      assert updated_issue.status == :resolved
      assert updated_issue.resolved_at

      # Give the worker a moment to stop cleanly after marking issue as resolved
      Process.sleep(100)

      # Assert that the worker process has stopped and is not restarted
      assert_worker_stopped(issue.id)

      # Verify that a remediation plan was created and saved to the database
      plans = RemediationPlans.find_remediation_plans_by_issue(issue.id)
      assert length(plans) == 1

      plan = List.first(plans)
      assert plan.success_delay_ms == 500
      # Should have advanced past the completed action
      assert plan.current_action_index == 1
      assert length(plan.actions) == 1

      action = List.first(plan.actions)
      assert action.action_type == :delete_resource
      assert action.params["name"] == "test-pod"
      assert action.params["namespace"] == "default"
      assert action.result == %{"deleted" => true}
      assert action.executed_at
    end

    test "handles preflight check failure and marks issue as failed", %{issue: issue} do
      # Mock the handler to simulate failed preflight check
      stub(MockStaleResourceHandler, :preflight, fn _issue ->
        {:error, :not_stale}
      end)

      # Start the worker manually (not supervised) so it can stop normally without restart
      {:ok, worker_pid} =
        IssueWorker.start_link(
          issue: issue,
          analysis_delay_ms: 50,
          stale_resource_handler: MockStaleResourceHandler,
          delete_resource_executor: MockDeleteResourceExecutor
        )

      # Allow the worker to call our mocks
      allow(MockStaleResourceHandler, self(), worker_pid)
      allow(MockDeleteResourceExecutor, self(), worker_pid)

      # Wait for the issue to transition to failed status using database events
      case wait_for_issue_status(issue.id, :failed) do
        :ok ->
          :ok

        {:error, {:timeout, expected, actual}} ->
          flunk("Timeout waiting for issue to reach #{expected}, currently #{actual}")
      end

      # Verify the issue was marked as failed due to preflight failure
      updated_issue = Issues.get_issue!(issue.id)
      assert updated_issue.status == :failed

      # Give the worker a moment to stop cleanly after marking issue as failed
      Process.sleep(100)

      # Assert that the worker process has stopped and is not restarted
      assert_worker_stopped(issue.id)
    end

    test "handles skipped preflight check and marks issue as resolved", %{issue: issue} do
      # Mock the handler to simulate skipped preflight check (resource already gone)
      stub(MockStaleResourceHandler, :preflight, fn _issue ->
        {:ok, :skip}
      end)

      # Start the worker manually (not supervised) so it can stop normally without restart
      {:ok, worker_pid} =
        IssueWorker.start_link(
          issue: issue,
          analysis_delay_ms: 50,
          stale_resource_handler: MockStaleResourceHandler,
          delete_resource_executor: MockDeleteResourceExecutor
        )

      # Allow the worker to call our mocks
      allow(MockStaleResourceHandler, self(), worker_pid)
      allow(MockDeleteResourceExecutor, self(), worker_pid)

      # Wait for the issue to transition to resolved status using database events
      case wait_for_issue_status(issue.id, :resolved) do
        :ok ->
          :ok

        {:error, {:timeout, expected, actual}} ->
          flunk("Timeout waiting for issue to reach #{expected}, currently #{actual}")
      end

      # Verify the issue was marked as resolved (nothing needed to be done)
      updated_issue = Issues.get_issue!(issue.id)
      assert updated_issue.status == :resolved
      assert updated_issue.resolved_at

      # Give the worker a moment to stop cleanly after marking issue as resolved
      Process.sleep(100)

      # Assert that the worker process has stopped and is not restarted
      assert_worker_stopped(issue.id)
    end

    test "creates and updates remediation plan throughout the process", %{issue: issue} do
      # Mock the handler to simulate multi-step plan with a failure and retry
      plan_template = %{
        retry_delay_ms: 1000,
        success_delay_ms: 500,
        max_retries: 2,
        current_action_index: 0,
        actions: [
          %{action_type: :delete_resource, params: %{name: "test-pod", namespace: "default", api_version_kind: "pod"}},
          %{
            action_type: :delete_resource,
            params: %{name: "test-service", namespace: "default", api_version_kind: "service"}
          }
        ]
      }

      # First action fails, second succeeds
      call_count = :counters.new(1, [])

      stub(MockStaleResourceHandler, :preflight, fn _issue -> {:ok, :ready} end)
      stub(MockStaleResourceHandler, :plan, fn _issue -> {:ok, plan_template} end)
      stub(MockStaleResourceHandler, :verify, fn _issue -> {:ok, :resolved} end)

      stub(MockDeleteResourceExecutor, :execute, fn action ->
        count = :counters.get(call_count, 1)
        :counters.add(call_count, 1, 1)

        case {count, action.params["name"]} do
          {0, "test-pod"} -> {:error, :resource_not_found}
          # Retry succeeds
          {1, "test-pod"} -> {:ok, %{"deleted" => true}}
          {_, "test-service"} -> {:ok, %{"deleted" => true}}
        end
      end)

      # Start the worker
      {:ok, worker_pid} =
        IssueWorker.start_link(
          issue: issue,
          analysis_delay_ms: 50,
          stale_resource_handler: MockStaleResourceHandler,
          delete_resource_executor: MockDeleteResourceExecutor
        )

      allow(MockStaleResourceHandler, self(), worker_pid)
      allow(MockDeleteResourceExecutor, self(), worker_pid)

      # Wait for resolution
      case wait_for_issue_status(issue.id, :resolved) do
        :ok ->
          :ok

        {:error, {:timeout, expected, actual}} ->
          flunk("Timeout waiting for issue to reach #{expected}, currently #{actual}")
      end

      Process.sleep(100)

      # Verify plan was created with correct structure
      plans = RemediationPlans.find_remediation_plans_by_issue(issue.id)
      assert length(plans) == 1

      plan = List.first(plans)
      assert plan.retry_delay_ms == 1000
      assert plan.success_delay_ms == 500
      assert plan.max_retries == 2
      assert length(plan.actions) == 2

      # Verify actions were saved with results
      [action1, action2] = Enum.sort_by(plan.actions, & &1.order_index)

      assert action1.action_type == :delete_resource
      assert action1.params["name"] == "test-pod"
      assert action1.result == %{"deleted" => true}
      assert action1.executed_at

      assert action2.action_type == :delete_resource
      assert action2.params["name"] == "test-service"
      assert action2.result == %{"deleted" => true}
      assert action2.executed_at
    end

    test "retries failed actions within the retry limit", %{issue: issue} do
      # Mock the handler to simulate a plan with a single action that fails then succeeds
      plan_template = %{
        retry_delay_ms: 100,
        success_delay_ms: 500,
        max_retries: 3,
        current_action_index: 0,
        actions: [
          %{
            action_type: :delete_resource,
            params: %{name: "test-pod", namespace: "default", api_version_kind: "pod"}
          }
        ]
      }

      # Track call attempts - fail twice, then succeed
      call_count = :counters.new(1, [])

      stub(MockStaleResourceHandler, :preflight, fn _issue -> {:ok, :ready} end)
      stub(MockStaleResourceHandler, :plan, fn _issue -> {:ok, plan_template} end)
      stub(MockStaleResourceHandler, :verify, fn _issue -> {:ok, :resolved} end)

      stub(MockDeleteResourceExecutor, :execute, fn _action ->
        count = :counters.get(call_count, 1)
        :counters.add(call_count, 1, 1)

        case count do
          0 -> {:error, :network_timeout}
          1 -> {:error, :temporary_failure}
          2 -> {:ok, %{"deleted" => true}}
          _ -> {:ok, %{"deleted" => true}}
        end
      end)

      # Start the worker
      {:ok, worker_pid} =
        IssueWorker.start_link(
          issue: issue,
          analysis_delay_ms: 50,
          stale_resource_handler: MockStaleResourceHandler,
          delete_resource_executor: MockDeleteResourceExecutor
        )

      allow(MockStaleResourceHandler, self(), worker_pid)
      allow(MockDeleteResourceExecutor, self(), worker_pid)

      # Wait for resolution
      case wait_for_issue_status(issue.id, :resolved) do
        :ok ->
          :ok

        {:error, {:timeout, expected, actual}} ->
          flunk("Timeout waiting for issue to reach #{expected}, currently #{actual}")
      end

      Process.sleep(100)

      # Verify the action eventually succeeded after retries
      plans = RemediationPlans.find_remediation_plans_by_issue(issue.id)
      assert length(plans) == 1

      plan = List.first(plans)
      assert length(plan.actions) == 1

      action = List.first(plan.actions)
      assert action.action_type == :delete_resource
      assert action.result == %{"deleted" => true}
      assert action.executed_at

      # Verify that the executor was called 3 times (2 failures + 1 success)
      final_call_count = :counters.get(call_count, 1)
      assert final_call_count == 3

      # Verify the issue is resolved (retry_count gets reset to 0 on resolution)
      final_issue = Issues.get_issue!(issue.id)
      assert final_issue.status == :resolved
      assert final_issue.retry_count == 0
    end

    test "handles external issue update to resolved before analysis timer", %{issue: issue} do
      # Use a long analysis delay to ensure we can update the issue before analysis starts
      analysis_delay_ms = 2000

      # Mock the handler - these shouldn't actually be called since we'll resolve externally
      stub(MockStaleResourceHandler, :preflight, fn _issue -> {:ok, :ready} end)
      stub(MockStaleResourceHandler, :plan, fn _issue -> flunk("Plan should not be called") end)
      stub(MockStaleResourceHandler, :verify, fn _issue -> flunk("Verify should not be called") end)

      # Start the worker with a long analysis delay
      {:ok, worker_pid} =
        IssueWorker.start_link(
          issue: issue,
          analysis_delay_ms: analysis_delay_ms,
          stale_resource_handler: MockStaleResourceHandler,
          delete_resource_executor: MockDeleteResourceExecutor
        )

      allow(MockStaleResourceHandler, self(), worker_pid)
      allow(MockDeleteResourceExecutor, self(), worker_pid)

      # Wait a moment to ensure the worker has started and scheduled the analysis timer
      Process.sleep(100)

      # Manually resolve the issue before the analysis timer fires
      {:ok, _updated_issue} = Issues.update_issue(issue, %{status: :resolved})

      # The worker should stop when it receives the update notification
      Process.sleep(200)

      # Verify the worker has stopped
      assert_worker_stopped(issue.id)

      # Verify the issue is resolved
      final_issue = Issues.get_issue!(issue.id)
      assert final_issue.status == :resolved
    end

    test "handles external issue update to failed before analysis timer", %{issue: issue} do
      # Use a long analysis delay to ensure we can update the issue before analysis starts
      analysis_delay_ms = 2000

      # Mock the handler - these shouldn't actually be called since we'll fail externally
      stub(MockStaleResourceHandler, :preflight, fn _issue -> {:ok, :ready} end)
      stub(MockStaleResourceHandler, :plan, fn _issue -> flunk("Plan should not be called") end)
      stub(MockStaleResourceHandler, :verify, fn _issue -> flunk("Verify should not be called") end)

      # Start the worker with a long analysis delay
      {:ok, worker_pid} =
        IssueWorker.start_link(
          issue: issue,
          analysis_delay_ms: analysis_delay_ms,
          stale_resource_handler: MockStaleResourceHandler,
          delete_resource_executor: MockDeleteResourceExecutor
        )

      allow(MockStaleResourceHandler, self(), worker_pid)
      allow(MockDeleteResourceExecutor, self(), worker_pid)

      # Wait a moment to ensure the worker has started and scheduled the analysis timer
      Process.sleep(100)

      # Manually fail the issue before the analysis timer fires
      {:ok, _updated_issue} = Issues.update_issue(issue, %{status: :failed})

      # The worker should stop when it receives the update notification
      Process.sleep(200)

      # Verify the worker has stopped
      assert_worker_stopped(issue.id)

      # Verify the issue is failed
      final_issue = Issues.get_issue!(issue.id)
      assert final_issue.status == :failed
    end
  end
end
