defmodule CommonCore.Actions.RootGeneratorTest do
  use ExUnit.Case

  import CommonCore.Factory

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Actions.RootActionGenerator

  defp assert_valid(value) do
    assert %FreshGeneratedAction{} = value
    value
  end

  describe "RootActionGenerator works" do
    test "all battery resources are valid" do
      :install_spec
      |> build(usage: :kitchen_sink, kube_provider: :aws)
      |> then(fn install_spec -> install_spec.target_summary end)
      |> RootActionGenerator.materialize()
      |> Enum.map(&assert_valid/1)
      # ensure that some actions are generated
      |> then(fn values -> assert length(values) > 0 end)
    end
  end
end
