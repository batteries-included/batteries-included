defmodule KubeResources.MLTest do
  use ExUnit.Case

  alias KubeResources.Notebooks
  import KubeResources.ControlServerFactory

  require Logger

  describe "ML" do
    test "Can materialize no notebooks" do
      assert map_size(Notebooks.materialize(%{config: %{}}, %{notebooks: []})) >= 1
    end

    test "can materialize with a notebook" do
      # Should include the service
      # account, the statefulsets, and the service.
      assert map_size(Notebooks.materialize(%{config: %{}}, %{notebooks: [build(:notebook)]})) >=
               3
    end
  end
end
