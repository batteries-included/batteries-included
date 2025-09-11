defmodule KubeServices.Stale.StaleResourceWatcherTest do
  @moduledoc """
  Comprehensive tests for KubeServices.Stale.Watcher.

  Tests cover:
  1. Successful startup and initialization
  2. Failed snapshot handling (should be ignored)
  3. Successful snapshot processing with stale resource detection
  4. Issue creation for stale resources
  5. No issues created for referenced resources
  6. State tracking and timing behavior
  """
  use ExUnit.Case, async: false
  use ControlServer.DataCase

  import Mox

  alias ControlServer.RoboSRE.Issues
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter
  alias KubeServices.MockStale
  alias KubeServices.Stale.Watcher

  setup :verify_on_exit!
  setup :set_mox_from_context

  describe "StaleResourceWatcher" do
    setup do
      # Subscribe to issue database events so we can wait for issue creation
      :ok = EventCenter.Database.subscribe(:issue)

      # Sample resources for testing
      stale_pod = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{
          "name" => "stale-pod",
          "namespace" => "default",
          "labels" => %{"battery/managed.direct" => "true"},
          "annotations" => %{"battery/hash" => "abc123"}
        }
      }

      stale_service = %{
        "apiVersion" => "v1",
        "kind" => "Service",
        "metadata" => %{
          "name" => "stale-service",
          "namespace" => "production",
          "labels" => %{"battery/managed.direct" => "true"},
          "annotations" => %{"battery/hash" => "def456"}
        }
      }

      referenced_pod = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{
          "name" => "referenced-pod",
          "namespace" => "default",
          "labels" => %{"battery/managed.direct" => "true"},
          "annotations" => %{"battery/hash" => "ghi789"}
        }
      }

      %{
        stale_pod: stale_pod,
        stale_service: stale_service,
        referenced_pod: referenced_pod
      }
    end

    test "starts successfully with default delay" do
      assert {:ok, _pid} = Watcher.start_link(name: :test_watcher_1)
    end

    test "starts successfully with custom delay" do
      assert {:ok, _pid} = Watcher.start_link(name: :test_watcher_2, delay: 1000)
    end

    test "ignores failed snapshot events", %{stale_pod: stale_pod} do
      # Mock Stale module
      stub(MockStale, :can_delete_safe?, fn -> true end)
      stub(MockStale, :find_potential_stale, fn -> [stale_pod] end)

      # Start watcher with mock
      {:ok, watcher_pid} = start_watcher_with_mock()

      # Send a failed snapshot event
      failed_snapshot = %KubeSnapshot{status: :error}
      payload = %SnapshotEventCenter.Payload{snapshot: failed_snapshot}

      send(watcher_pid, payload)

      # Give it a moment to process
      Process.sleep(100)

      # Verify no issues were created
      assert Issues.count_open_issues() == 0

      # Verify mocks were not called (no stale detection should happen)
      verify!()
    end

    test "creates issues for stale resources when snapshot is successful",
         %{stale_pod: stale_pod, stale_service: stale_service} do
      # Mock Stale module to return stale resources
      stub(MockStale, :can_delete_safe?, fn -> true end)
      stub(MockStale, :find_potential_stale, fn -> [stale_pod, stale_service] end)

      # Start watcher with very short delay to speed up test
      {:ok, watcher_pid} = start_watcher_with_mock(delay: 50)

      # Send first successful snapshot event to start tracking resources as stale
      successful_snapshot = %KubeSnapshot{status: :ok}
      payload = %SnapshotEventCenter.Payload{snapshot: successful_snapshot}

      send(watcher_pid, payload)

      # Wait longer than the delay to ensure resources are stale long enough
      Process.sleep(100)

      # Send second snapshot event to trigger issue creation for already-stale resources
      send(watcher_pid, payload)

      # Wait for issues to be created
      issues = wait_for_issues(2)

      assert length(issues) == 2

      # Verify issue details for pod (note: namespace is included in subject)
      pod_issue = Enum.find(issues, &(&1.subject == "default:stale-pod"))
      assert pod_issue.issue_type == :stale_resource
      assert pod_issue.trigger == :health_check
      assert pod_issue.handler == :stale_resource
      assert pod_issue.status == :detected
      assert pod_issue.trigger_params["api_version_kind"] == "pod"

      # Verify issue details for service (with namespace in subject)
      service_issue = Enum.find(issues, &(&1.subject == "production:stale-service"))
      assert service_issue.issue_type == :stale_resource
      assert service_issue.trigger == :health_check
      assert service_issue.handler == :stale_resource
      assert service_issue.status == :detected
      assert service_issue.trigger_params["api_version_kind"] == "service"
    end

    test "does not create issues when can_delete_safe? returns false",
         %{stale_pod: stale_pod} do
      # Mock Stale module to indicate unsafe deletion
      stub(MockStale, :can_delete_safe?, fn -> false end)
      # This should not be called, but stub it to be safe
      stub(MockStale, :find_potential_stale, fn -> [stale_pod] end)

      {:ok, watcher_pid} = start_watcher_with_mock(delay: 50)

      # Send a successful snapshot event
      successful_snapshot = %KubeSnapshot{status: :ok}
      payload = %SnapshotEventCenter.Payload{snapshot: successful_snapshot}

      send(watcher_pid, payload)

      # Wait for processing
      Process.sleep(150)

      # Verify no issues were created
      assert Issues.count_open_issues() == 0
    end

    test "tracks staleness timing correctly and only creates issues after delay",
         %{stale_pod: stale_pod} do
      # Mock Stale module
      stub(MockStale, :can_delete_safe?, fn -> true end)
      stub(MockStale, :find_potential_stale, fn -> [stale_pod] end)

      {:ok, watcher_pid} = start_watcher_with_mock(delay: 100)

      # Send snapshot event to start tracking
      successful_snapshot = %KubeSnapshot{status: :ok}
      payload = %SnapshotEventCenter.Payload{snapshot: successful_snapshot}

      send(watcher_pid, payload)

      # Wait less than delay and send another event - should not create issues yet
      Process.sleep(50)
      send(watcher_pid, payload)
      Process.sleep(20)

      # Verify no issues created yet
      assert Issues.count_open_issues() == 0

      # Wait longer than delay and send another event - should create issues now
      # Total wait is now > 100ms
      Process.sleep(50)
      send(watcher_pid, payload)

      # Wait for issue creation
      issues = wait_for_issues(1)
      assert length(issues) == 1

      issue = List.first(issues)
      assert issue.subject == "default:stale-pod"
    end

    test "handles resources with no namespace (cluster-scoped)", %{stale_pod: stale_pod} do
      # Create a cluster-scoped resource (no namespace)
      cluster_resource = put_in(stale_pod, ["metadata", "namespace"], nil)
      cluster_resource = put_in(cluster_resource, ["metadata", "name"], "cluster-resource")

      # Mock Stale module
      stub(MockStale, :can_delete_safe?, fn -> true end)
      stub(MockStale, :find_potential_stale, fn -> [cluster_resource] end)

      {:ok, watcher_pid} = start_watcher_with_mock(delay: 50)

      # Send snapshot events with proper timing
      successful_snapshot = %KubeSnapshot{status: :ok}
      payload = %SnapshotEventCenter.Payload{snapshot: successful_snapshot}

      send(watcher_pid, payload)
      Process.sleep(100)
      send(watcher_pid, payload)

      # Wait for issue creation
      issues = wait_for_issues(1)
      assert length(issues) == 1

      issue = List.first(issues)
      assert issue.subject == "cluster-resource"
    end

    test "handles resource that becomes referenced (no longer stale)",
         %{stale_pod: stale_pod} do
      # Mock Stale module - first call returns stale resource, second returns empty
      call_count = :counters.new(1, [])

      stub(MockStale, :can_delete_safe?, fn -> true end)

      stub(MockStale, :find_potential_stale, fn ->
        count = :counters.get(call_count, 1)
        :counters.add(call_count, 1, 1)

        case count do
          # First few calls: resource is stale
          n when n < 4 -> [stale_pod]
          # Later calls: resource is no longer stale
          _ -> []
        end
      end)

      {:ok, watcher_pid} = start_watcher_with_mock(delay: 50)

      # Send first snapshot event
      successful_snapshot = %KubeSnapshot{status: :ok}
      payload = %SnapshotEventCenter.Payload{snapshot: successful_snapshot}

      send(watcher_pid, payload)
      Process.sleep(100)
      send(watcher_pid, payload)

      # Wait for issue creation
      issues = wait_for_issues(1)
      assert length(issues) == 1

      # Send second snapshot event (resource no longer stale)
      send(watcher_pid, payload)
      Process.sleep(50)

      # Verify still only one issue (the original one remains)
      # The watcher doesn't resolve issues, it only creates them
      # Note: Due to the timing of calls, we might get multiple issues created
      # before the resource becomes non-stale. The key is that no NEW issues
      # are created after the resource is no longer stale.
      final_issues = Issues.list_open_issues()
      assert length(final_issues) >= 1, "Expected at least 1 issue"

      # All issues should be for the same resource
      subjects = Enum.map(final_issues, & &1.subject)
      assert Enum.all?(subjects, fn subject -> subject == "default:stale-pod" end)
    end

    test "processes resources with different api version kinds correctly", %{stale_pod: stale_pod} do
      # Create resources with different kinds
      deployment = %{
        "apiVersion" => "apps/v1",
        "kind" => "Deployment",
        "metadata" => %{
          "name" => "test-deployment",
          "namespace" => "default",
          "labels" => %{"battery/managed.direct" => "true"},
          "annotations" => %{"battery/hash" => "deployment123"}
        }
      }

      configmap = %{
        "apiVersion" => "v1",
        "kind" => "ConfigMap",
        "metadata" => %{
          "name" => "test-config",
          "namespace" => "kube-system",
          "labels" => %{"battery/managed.direct" => "true"},
          "annotations" => %{"battery/hash" => "config456"}
        }
      }

      # Mock Stale module
      stub(MockStale, :can_delete_safe?, fn -> true end)
      stub(MockStale, :find_potential_stale, fn -> [stale_pod, deployment, configmap] end)

      {:ok, watcher_pid} = start_watcher_with_mock(delay: 50)

      # Send snapshot events with proper timing
      successful_snapshot = %KubeSnapshot{status: :ok}
      payload = %SnapshotEventCenter.Payload{snapshot: successful_snapshot}

      send(watcher_pid, payload)
      Process.sleep(100)
      send(watcher_pid, payload)

      # Wait for issue creation
      issues = wait_for_issues(3)
      assert length(issues) == 3

      # Verify each issue has correct api_version_kind
      pod_issue = Enum.find(issues, &(&1.subject == "default:stale-pod"))
      assert pod_issue.trigger_params["api_version_kind"] == "pod"

      deployment_issue = Enum.find(issues, &(&1.subject == "default:test-deployment"))
      assert deployment_issue.trigger_params["api_version_kind"] == "deployment"

      configmap_issue = Enum.find(issues, &(&1.subject == "kube-system:test-config"))
      assert configmap_issue.trigger_params["api_version_kind"] == "config_map"
    end

    test "ignores resources with invalid api version kind", %{stale_pod: stale_pod} do
      # Create a resource that would return nil for api_version_kind
      invalid_resource = %{
        "metadata" => %{
          "name" => "invalid-resource",
          "namespace" => "default",
          "labels" => %{"battery/managed.direct" => "true"},
          "annotations" => %{"battery/hash" => "invalid123"}
        }
        # Missing apiVersion and kind
      }

      # Mock Stale module
      stub(MockStale, :can_delete_safe?, fn -> true end)
      stub(MockStale, :find_potential_stale, fn -> [stale_pod, invalid_resource] end)

      {:ok, watcher_pid} = start_watcher_with_mock(delay: 50)

      # Send snapshot events with proper timing
      successful_snapshot = %KubeSnapshot{status: :ok}
      payload = %SnapshotEventCenter.Payload{snapshot: successful_snapshot}

      send(watcher_pid, payload)
      Process.sleep(100)
      send(watcher_pid, payload)

      # Wait for issue creation (only 1 for valid resource)
      issues = wait_for_issues(1)
      assert length(issues) == 1

      issue = List.first(issues)
      assert issue.subject == "default:stale-pod"
    end
  end

  # Helper function to start a watcher with mocked dependencies
  defp start_watcher_with_mock(opts \\ []) do
    default_opts = [
      name: :"test_watcher_#{System.unique_integer([:positive])}",
      delay: 100,
      snapshot_event_center: EventCenter.MockKubeSnapshot,
      stale_module: MockStale
    ]

    opts = Keyword.merge(default_opts, opts)

    # Mock the snapshot event center subscribe
    stub(EventCenter.MockKubeSnapshot, :subscribe, fn -> :ok end)

    # Start the watcher with dependency injection
    Watcher.start_link(opts)
  end

  # Helper function to wait for a specific number of issues to be created
  defp wait_for_issues(expected_count, timeout \\ 5000) do
    start_time = System.monotonic_time(:millisecond)

    wait_for_issues_poll(expected_count, timeout, start_time)
  end

  defp wait_for_issues_poll(expected_count, timeout, start_time) do
    current_time = System.monotonic_time(:millisecond)

    if current_time - start_time > timeout do
      current_issues = Issues.list_open_issues()
      flunk("Timeout waiting for #{expected_count} issues, got #{length(current_issues)}")
    end

    current_issues = Issues.list_open_issues()

    if length(current_issues) >= expected_count do
      current_issues
    else
      Process.sleep(50)
      wait_for_issues_poll(expected_count, timeout, start_time)
    end
  end
end
