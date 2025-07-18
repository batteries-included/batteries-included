defmodule CommonCore.Resources.AITest do
  use ExUnit.Case

  import CommonCore.Factory

  alias CommonCore.Resources.Notebooks
  alias CommonCore.StateSummary

  require Logger

  describe "AI" do
    test "Can materialize no notebooks" do
      battery = %{config: %{}, type: :notebooks}
      state = %StateSummary{notebooks: []}
      assert map_size(Notebooks.materialize(battery, state)) >= 1
    end

    test "can materialize with a notebook" do
      # Should include the service
      # account, the statefulsets, and the service.
      battery = %{config: %{}, type: :notebooks}
      state = %StateSummary{notebooks: [build(:notebook)]}
      assert map_size(Notebooks.materialize(battery, state)) >= 3
    end
  end
end
