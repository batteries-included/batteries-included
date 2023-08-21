defmodule CommonCore.Actions.RootGeneratorTest do
  use ExUnit.Case

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Actions.RootActionGenerator

  defp assert_valid(value) do
    assert %FreshGeneratedAction{} = value
  end

  describe "RootActionGenerator works" do
    test "all battery resources are valid" do
      # Pull what we would write to seed the database into the action generator.
      # Then try and materialize everything.
      #
      # In the end it's a pretty good code coverage for produces something reasonable
      :everything
      |> CommonCore.StateSummary.SeedState.seed()
      |> RootActionGenerator.materialize()
      |> Enum.each(&assert_valid/1)
    end
  end
end
