defmodule CommonCore.Actions.RootGeneratorTest do
  use ExUnit.Case

  import CommonCore.Factory

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Actions.RootActionGenerator

  defp assert_valid(value) do
    assert %FreshGeneratedAction{} = value
  end

  describe "RootActionGenerator works" do
    test "all battery resources are valid" do
      :install_spec
      |> build(usage: :kitchen_sink, kube_provider: :aws)
      |> then(fn install_spec -> install_spec.target_summary end)
      |> RootActionGenerator.materialize()
      |> Enum.each(&assert_valid/1)
    end
  end
end
