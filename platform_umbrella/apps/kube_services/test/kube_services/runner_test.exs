defmodule KubeServices.KubeState.RunnerTest do
  use ExUnit.Case

  alias KubeServices.KubeState
  alias KubeServices.KubeState.Runner

  @table_name :runner_test_state_table

  setup _context do
    start_supervised!({Runner, name: @table_name})

    :ok
  end

  describe "KubeState.Runner" do
    test "KubeState.pods/1 gives back added pods." do
      pod_one = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "One", "namespace" => "battery-core"}
      }

      pod_two = %{
        "apiVersion" => "v1",
        "kind" => "Pod",
        "metadata" => %{"name" => "Two", "namespace" => "battery-core"}
      }

      Runner.add(@table_name, pod_one)
      Runner.add(@table_name, pod_two)

      result = KubeState.get_all(@table_name, :pod)

      assert Enum.any?(result, fn r -> Map.equal?(r, pod_one) end)
      assert Enum.any?(result, fn r -> Map.equal?(r, pod_two) end)
      assert Enum.count(result) == 2
    end
  end
end
