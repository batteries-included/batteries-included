defmodule CommonCore.Actions.RootGeneratorTest do
  alias CommonCore.Actions.RootActionGenerator
  alias CommonCore.Actions.BaseAction

  use ExUnit.Case

  defp assert_valid(value) do
    assert %BaseAction{} = value
  end

  describe "RootActionGenerator works" do
    test "all battery resources are valid" do
      # Pull what we would write to seed the database into the action generator.
      # Then try and materialize everything.
      #
      # In the end it's a pretty good code coverage for produces something reasonable
      CommonCore.StateSummary.SeedState.seed(:everything)
      |> RootActionGenerator.materialize()
      |> Enum.each(&assert_valid/1)
    end
  end
end
