defmodule KubeResources.MLTest do
  use ExUnit.Case

  alias KubeExt.SystemState.StateSummary
  alias KubeResources.Notebooks
  import KubeResources.ControlServerFactory

  require Logger

  describe "ML" do
    test "Can materialize no notebooks" do
      battery = %{config: %{}}
      state = %StateSummary{notebooks: []}
      assert map_size(Notebooks.materialize(battery, state)) >= 1
    end

    test "can materialize with a notebook" do
      # Should include the service
      # account, the statefulsets, and the service.
      battery = %{config: %{}}
      state = %StateSummary{notebooks: [build(:notebook)]}
      assert map_size(Notebooks.materialize(battery, state)) >= 3
    end
  end
end
