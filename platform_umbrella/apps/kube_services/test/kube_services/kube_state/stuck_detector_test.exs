defmodule KubeServices.KubeState.StuckDetectorTest do
  @moduledoc """
  Tests for the StuckDetector GenServer that monitors KubeState for drift.
  """
  use ExUnit.Case, async: false
  use ControlServer.DataCase

  import ControlServer.Factory
  import Mox

  alias ControlServer.RoboSRE.Issues
  alias KubeServices.K8s.MockClient
  alias KubeServices.KubeState.StuckDetector
  alias KubeServices.MockKubeState

  setup :verify_on_exit!
  setup :set_mox_from_context

  describe "StuckDetector" do
    setup do
      # Start the detector with test configuration
      detector_opts = [
        name: :"test_detector_#{System.unique_integer([:positive])}",
        # 1 minute for tests
        check_interval: 60_000,
        # 10% threshold
        drift_threshold: 0.1,
        # Sample 50% of pods, 100% of services
        sample_percentages: %{pod: 0.5, service: 1.0},
        default_sample_percentage: 0.25,
        kube_state: MockKubeState,
        client: MockClient,
        issues_context: Issues,
        connection: :fake_connection
      ]

      {:ok, detector_pid} = StuckDetector.start_link(detector_opts)
      detector_name = detector_opts[:name]

      %{detector_pid: detector_pid, detector_name: detector_name}
    end

    test "starts successfully and schedules periodic checks", %{detector_pid: detector_pid} do
      assert Process.alive?(detector_pid)
    end

    test "check_now triggers immediate drift check", %{detector_name: detector_name} do
      # Mock snapshot with no resources
      stub(MockKubeState, :snapshot, fn -> %{} end)

      assert :ok = StuckDetector.check_now(detector_name)
    end

    test "detects no drift when no resources exist", %{detector_name: detector_name} do
      # Mock empty snapshot
      stub(MockKubeState, :snapshot, fn -> %{} end)

      assert :ok = StuckDetector.check_now(detector_name)

      # Should not create any issues
      assert Issues.count_open_issues() == 0
    end

    test "detects no drift when all resources match cluster state", %{detector_name: detector_name} do
      # Create test resources
      pod_resource = build_pod_resource("test-pod", "default")
      service_resource = build_service_resource("test-service", "default")

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn ->
        %{pod: [pod_resource], service: [service_resource]}
      end)

      # Mock client to return same resources (no drift)
      stub(MockClient, :get, fn _, _, _ -> build_get_operation() end)
      stub(MockClient, :run, fn _, _ -> {:ok, pod_resource} end)

      assert :ok = StuckDetector.check_now(detector_name)

      # Should not create any issues
      assert Issues.count_open_issues() == 0
    end

    test "detects drift when resource hashes differ", %{detector_name: detector_name} do
      # Create test resources
      snapshot_pod = build_pod_resource("test-pod", "default")
      cluster_pod = build_pod_resource("test-pod", "default", %{"different" => "annotation"})

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn -> %{pod: [snapshot_pod]} end)

      # Mock client to return different resource (drift detected)
      stub(MockClient, :get, fn _, _, _ -> build_get_operation(:pod) end)
      stub(MockClient, :run, fn _, _ -> {:ok, cluster_pod} end)

      assert :ok = StuckDetector.check_now(detector_name)

      # Should create a stuck kubestate issue
      issues = Issues.list_open_issues()
      assert length(issues) == 1

      issue = List.first(issues)
      assert issue.issue_type == :stuck_kubestate
      assert issue.subject == "cluster.control_server.kube-state"
      assert issue.trigger == :health_check
      assert issue.trigger_params["drift_percentage"] > 0
      # Verify the issue contains expected drift information
      assert issue.trigger_params["drifting_resources"]["pod"] == [%{"namespace" => "default", "name" => "test-pod"}]
    end

    test "detects drift when resource exists in snapshot but not cluster", %{detector_name: detector_name} do
      # Create test resource
      pod_resource = build_pod_resource("missing-pod", "default")

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn -> %{pod: [pod_resource]} end)

      # Mock client to return 404 (resource missing from cluster)
      stub(MockClient, :get, fn _, _, _ -> build_get_operation(:pod) end)
      stub(MockClient, :run, fn _, _ -> {:error, %{status: 404}} end)

      assert :ok = StuckDetector.check_now(detector_name)

      # Should create a stuck kubestate issue
      issues = Issues.list_open_issues()
      assert length(issues) == 1

      issue = List.first(issues)
      assert issue.issue_type == :stuck_kubestate
      assert issue.trigger_params["drifting_resources"]["pod"] == [%{"namespace" => "default", "name" => "missing-pod"}]
    end

    test "respects drift threshold", %{detector_name: detector_name} do
      # Create 10 pods - all will match (0% drift, threshold is 10%)
      pods = for i <- 1..10, do: build_pod_resource("pod-#{i}", "default")

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn -> %{pod: pods} end)

      # Mock client - all resources match (no drift)
      stub(MockClient, :get, fn _, _, _ -> build_get_operation(:pod) end)

      stub(MockClient, :run, fn _, _ ->
        # Return matching resources (same hash)
        {:ok, build_pod_resource("test", "default")}
      end)

      assert :ok = StuckDetector.check_now(detector_name)

      # With 0% drift and 10% threshold, should NOT create issue
      assert Issues.count_open_issues() == 0
    end

    test "creates issue when drift exceeds threshold", %{detector_name: detector_name} do
      # Create 10 pods, 2 will be drifted (20% drift, threshold is 10%)
      pods = for i <- 1..10, do: build_pod_resource("pod-#{i}", "default")

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn -> %{pod: pods} end)

      # Mock client - first two pods drift, others match
      call_count = :counters.new(1, [])

      stub(MockClient, :get, fn _, _, _ -> build_get_operation(:pod) end)

      stub(MockClient, :run, fn _, _ ->
        count = :counters.get(call_count, 1)
        :counters.add(call_count, 1, 1)

        if count < 2 do
          # First two calls return different resources (drift)
          {:ok, build_pod_resource("pod-#{count + 1}", "default", %{"different" => "true"})}
        else
          # Subsequent calls return matching resources
          {:ok, build_pod_resource("pod-#{count + 1}", "default")}
        end
      end)

      assert :ok = StuckDetector.check_now(detector_name)

      # With 2/10 = 20% drift and 10% threshold, should create issue
      issues = Issues.list_open_issues()
      assert length(issues) == 1

      issue = List.first(issues)
      assert issue.issue_type == :stuck_kubestate
      assert length(issue.trigger_params["drifting_resources"]["pod"]) == 2
    end

    test "creates issues without deduplicating at detector level", %{detector_name: detector_name} do
      # Create existing issue
      _existing_issue =
        insert(:issue, %{
          subject: "cluster.control_server.kube-state",
          issue_type: :stuck_kubestate,
          status: :detected
        })

      # Create drifted resource
      pod_resource = build_pod_resource("test-pod", "default")

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn -> %{pod: [pod_resource]} end)

      # Mock client to return different resource (drift detected)
      stub(MockClient, :get, fn _, _, _ -> build_get_operation(:pod) end)

      stub(MockClient, :run, fn _, _ ->
        {:ok, build_pod_resource("test-pod", "default", %{"different" => "true"})}
      end)

      assert :ok = StuckDetector.check_now(detector_name)

      # Should now have 2 issues since detector no longer deduplicates
      assert Issues.count_open_issues() == 2
    end

    test "recheck_drift calculates drift percentage for specific resources", %{detector_name: detector_name} do
      # Create test resources
      pod1 = build_pod_resource("pod-1", "default")
      pod2 = build_pod_resource("pod-2", "default")

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn -> %{pod: [pod1, pod2]} end)

      # Mock client - pod1 still drifts, pod2 now matches
      call_count = :counters.new(1, [])

      stub(MockClient, :get, fn _, _, _ -> build_get_operation(:pod) end)

      stub(MockClient, :run, fn _, _ ->
        count = :counters.get(call_count, 1)
        :counters.add(call_count, 1, 1)

        case count do
          # Still drifting
          0 -> {:ok, build_pod_resource("pod-1", "default", %{"different" => "true"})}
          # Now matches
          1 -> {:ok, pod2}
        end
      end)

      # Test recheck with both resources
      drifting_resources = %{pod: [%{namespace: "default", name: "pod-1"}, %{namespace: "default", name: "pod-2"}]}

      assert {:ok, drift_percentage} = StuckDetector.recheck_drift(drifting_resources, detector_name)

      # Only 1 out of 2 resources still drifting = 50%
      assert drift_percentage == 0.5
    end

    test "recheck_drift handles missing resources gracefully", %{detector_name: detector_name} do
      # Mock empty snapshot
      stub(MockKubeState, :snapshot, fn -> %{} end)

      # Test recheck with non-existent resources
      drifting_resources = %{pod: [%{namespace: "default", name: "missing-pod"}]}

      assert {:ok, drift_percentage} = StuckDetector.recheck_drift(drifting_resources, detector_name)

      # No resources found = 0% drift
      assert drift_percentage == 0.0
    end

    test "handles client errors gracefully", %{detector_name: detector_name} do
      # Create test resource
      pod_resource = build_pod_resource("test-pod", "default")

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn -> %{pod: [pod_resource]} end)

      # Mock client to return error
      stub(MockClient, :get, fn _, _, _ -> build_get_operation(:pod) end)
      stub(MockClient, :run, fn _, _ -> {:error, :timeout} end)

      assert :ok = StuckDetector.check_now(detector_name)

      # Should not create issues due to client errors
      assert Issues.count_open_issues() == 0
    end

    test "handles snapshot errors gracefully", %{detector_name: detector_name} do
      # Mock snapshot to raise error
      stub(MockKubeState, :snapshot, fn -> raise "snapshot failed" end)

      assert {:error, _} = StuckDetector.check_now(detector_name)
    end

    test "samples resources according to configuration", %{detector_name: detector_name} do
      # Create many pods (more than sample percentage)
      pods = for i <- 1..100, do: build_pod_resource("pod-#{i}", "default")

      # Mock snapshot
      stub(MockKubeState, :snapshot, fn -> %{pod: pods} end)

      # Track how many times client is called
      call_count = :counters.new(1, [])

      stub(MockClient, :get, fn _, _, _ -> build_get_operation(:pod) end)

      stub(MockClient, :run, fn _, _ ->
        :counters.add(call_count, 1, 1)
        # All match to avoid creating issues
        {:ok, build_pod_resource("test", "default")}
      end)

      assert :ok = StuckDetector.check_now(detector_name)

      # Should have sampled ~50 pods (50% of 100), not all 100
      calls_made = :counters.get(call_count, 1)
      # Allow some variance due to random sampling
      assert calls_made > 40 and calls_made < 60
    end
  end

  # Helper functions

  defp build_pod_resource(name, namespace, extra_annotations \\ %{}) do
    # Generate different hash based on extra annotations to simulate drift
    hash_suffix = if Enum.empty?(extra_annotations), do: "", else: "-different"
    base_annotations = %{"battery/hash" => "test-hash#{hash_suffix}"}
    annotations = Map.merge(base_annotations, extra_annotations)

    %{
      "apiVersion" => "v1",
      "kind" => "Pod",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace,
        "annotations" => annotations
      },
      "spec" => %{
        "containers" => [%{"name" => "test", "image" => "test:latest"}]
      }
    }
  end

  defp build_service_resource(name, namespace, extra_annotations \\ %{}) do
    # Generate different hash based on extra annotations to simulate drift
    hash_suffix = if Enum.empty?(extra_annotations), do: "", else: "-different"
    base_annotations = %{"battery/hash" => "test-hash#{hash_suffix}"}
    annotations = Map.merge(base_annotations, extra_annotations)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => name,
        "namespace" => namespace,
        "annotations" => annotations
      },
      "spec" => %{
        "selector" => %{"app" => name},
        "ports" => [%{"port" => 80, "targetPort" => 8080}]
      }
    }
  end

  defp build_get_operation(resource_type \\ :pod) do
    %{resource_type: resource_type}
  end
end
