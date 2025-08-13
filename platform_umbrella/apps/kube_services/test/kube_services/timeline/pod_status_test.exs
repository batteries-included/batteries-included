# credo:disable-for-this-file
defmodule KubeServices.Timeline.PodStatusTest do
  use ExUnit.Case, async: true

  import CommonCore.ResourceFactory

  alias KubeServices.Timeline.PodStatus

  require Logger

  @conditions ~w(Ready ContainersReady Initialized PodHasNetwork PodScheduled)

  setup do
    pid = start_supervised!({PodStatus, [table_name: :test, initial_sync_delay: 0]})
    %{pid: pid}
  end

  describe "upsert/2" do
    test "it adds the mapping if it's not already present", %{pid: pid} do
      pod = build(:pod)
      PodStatus.upsert(pid, pod)
      :sys.get_state(pid)
      assert length(PodStatus.dump()) == 1
    end

    test "it updates the mapping if it's already present", %{pid: pid} do
      pod = build(:pod)
      PodStatus.upsert(pid, pod)
      :sys.get_state(pid)
      assert length(PodStatus.dump()) == 1

      # mark pod not ready
      pod =
        update_in(pod, ~w(status)a, fn status ->
          Map.put(status || %{}, "conditions", [%{"type" => "Ready", "status" => "False"}])
        end)

      PodStatus.upsert(pid, pod)
      :sys.get_state(pid)
      assert length(PodStatus.dump()) == 1
    end
  end

  describe "delete/2" do
    test "it removes existing mapping", %{pid: pid} do
      pod = build(:pod)
      PodStatus.upsert(pid, pod)
      PodStatus.delete(pid, pod)
      assert length(PodStatus.dump()) == 0
    end

    test "it doesn't error on non-existent mapping", %{pid: pid} do
      pod = build(:pod)
      :ok = PodStatus.delete(pid, pod)
      assert length(PodStatus.dump()) == 0
    end
  end

  describe "dump/1" do
    test "it dumps the mapping", %{pid: pid} do
      upserts = Enum.random(51..100)
      deletes = Enum.random(1..50)

      for_result =
        for _ <- 1..upserts do
          pod = build(:pod)
          PodStatus.upsert(pid, pod)
          pod
        end

      for_result
      |> Enum.take(deletes)
      |> Enum.each(&PodStatus.delete(pid, &1))

      assert length(PodStatus.dump()) == upserts - deletes
    end
  end

  describe "status_changed?/2" do
    test "it returns {true, new_status} when status changes", %{pid: pid} do
      pod = build(:pod, %{"status" => %{"conditions" => [%{"type" => "Ready", "status" => "True"}]}})
      PodStatus.upsert(pid, pod)
      # Wait for the async upsert to complete
      :sys.get_state(pid)

      # Remove Ready condition, keep only ContainersReady
      pod = put_in(pod, ["status", "conditions"], [%{"type" => "ContainersReady", "status" => "True"}])

      assert {true, :containers_ready} = PodStatus.status_changed?(:test, pod)
    end

    test "it returns {false, status} when status didn't change", %{pid: pid} do
      pod = build(:pod)
      PodStatus.upsert(pid, pod)
      # Wait for the async upsert to complete
      :sys.get_state(pid)
      assert {false, _} = PodStatus.status_changed?(:test, pod)
    end

    test "it handles unknown statuses", %{pid: _pid} do
      pod = build(:pod, %{"status" => %{"conditions" => []}})
      # This pod was never upserted, so the table doesn't have it
      assert {_, :unknown} = PodStatus.status_changed?(:test, pod)
    end

    test "it handles all permutations of statuses", %{pid: pid} do
      for condition <- @conditions do
        pod = build(:pod, %{"status" => %{"conditions" => [%{"type" => condition, "status" => "True"}]}})
        PodStatus.upsert(pid, pod)
        # Wait for the async upsert to complete
        :sys.get_state(pid)

        for other <- @conditions do
          new_pod =
            update_in(pod, ~w(status), fn status ->
              Map.put(status || %{}, "conditions", [%{"type" => other, "status" => "True"}])
            end)

          if condition == other do
            # status hasn't changed, same condition type
            expected_status =
              case condition do
                "Ready" -> :ready
                "ContainersReady" -> :containers_ready
                "Initialized" -> :initialized
                "PodHasNetwork" -> :pod_has_network
                "PodScheduled" -> :pod_scheduled
                _ -> :unknown
              end

            assert {false, ^expected_status} = PodStatus.status_changed?(:test, new_pod)
          else
            # status has changed, new status should be based on other
            expected_status =
              case other do
                "Ready" -> :ready
                "ContainersReady" -> :containers_ready
                "Initialized" -> :initialized
                "PodHasNetwork" -> :pod_has_network
                "PodScheduled" -> :pod_scheduled
                _ -> :unknown
              end

            assert {true, ^expected_status} = PodStatus.status_changed?(:test, new_pod)
          end
        end
      end
    end
  end
end
