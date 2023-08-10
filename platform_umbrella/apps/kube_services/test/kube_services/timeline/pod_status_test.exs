# credo:disable-for-this-file
defmodule KubeServices.Timeline.PodStatusTest do
  use ExUnit.Case, async: true
  require Logger

  import KubeServices.Factory

  alias KubeServices.Timeline.PodStatus

  setup do
    pid = start_supervised!({PodStatus, [table_name: :test, initial_sync_delay: 0]})
    pod = build(:pod)
    %{pid: pid, pod: pod}
  end

  describe "upsert/2" do
    test "it adds the mapping if it's not already present", %{pid: pid, pod: pod} do
      PodStatus.upsert(pid, pod)
      assert length(PodStatus.dump()) == 1
    end

    test "it updates the mapping if it's already present", %{pid: pid, pod: pod} do
      PodStatus.upsert(pid, pod)
      assert length(PodStatus.dump()) == 1

      # mark pod not ready
      pod = with_conditions(pod, with_false_condition(pod["status"]["conditions"], "Ready"))
      PodStatus.upsert(pid, pod)
      assert length(PodStatus.dump()) == 1
    end
  end

  describe "delete/2" do
    test "it removes existing mapping", %{pid: pid, pod: pod} do
      PodStatus.upsert(pid, pod)
      PodStatus.delete(pid, pod)
      assert length(PodStatus.dump()) == 0
    end

    test "it doesn't error on non-existent mapping", %{pid: pid, pod: pod} do
      :ok = PodStatus.delete(pid, pod)
      assert length(PodStatus.dump()) == 0
      assert {_, ^pid, _, _} = :sys.get_status(PodStatus)
    end
  end

  describe "dump/1" do
    test "it dumps the mapping", %{pid: pid} do
      upserts = Enum.random(51..100)
      deletes = Enum.random(1..50)

      for _ <- 1..upserts do
        pod = build(:pod)
        PodStatus.upsert(pid, pod)
        pod
      end
      |> Enum.take(deletes)
      |> Enum.each(&PodStatus.delete(pid, &1))

      assert length(PodStatus.dump()) == upserts - deletes
    end
  end

  describe "status_changed?/2" do
    # seed the mapping with a ready pod
    setup %{pid: pid, pod: pod} do
      PodStatus.upsert(pid, pod)
      # to flush the server's messages
      _ = :sys.get_state(pid)
      assert {false, :ready} = PodStatus.status_changed?(:test, pod)
      :ok
    end

    test "it returns {true, new_status} when status changes", %{pid: _pid, pod: pod} do
      pod = with_conditions(pod, build(:conditions, condition: :containers_ready))
      assert {true, :containers_ready} = PodStatus.status_changed?(:test, pod)
    end

    test "it returns {false, status} when status didn't change", %{pid: _pid, pod: pod} do
      assert {false, :ready} = PodStatus.status_changed?(:test, pod)
    end

    test "it handles unknown statuses", %{pid: _pid, pod: pod} do
      pod = with_conditions(pod, build(:conditions, condition: :unknown))
      assert {true, :unknown} = PodStatus.status_changed?(:test, pod)
    end

    test "it handles all permutations of statuses", %{pid: pid, pod: _pod} do
      for {condition, _} <- get_container_status_mapping() ++ [unknown: "Unknown"] do
        pod = build(:pod) |> with_conditions(build(:conditions, condition: condition))
        PodStatus.upsert(pod)
        _ = :sys.get_state(pid)

        for {other, _} <- get_container_status_mapping() ++ [unknown: "Unknown"] do
          pod = with_conditions(pod, build(:conditions, condition: other))

          if other != condition do
            # status has changed, new status should be other
            assert {true, ^other} = PodStatus.status_changed?(:test, pod)
          else
            # status hasn't changed, new and old status are the same other == condition
            assert {false, ^other} = PodStatus.status_changed?(:test, pod)
          end
        end
      end
    end
  end
end
