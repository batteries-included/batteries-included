defmodule KubeResources.MLTest do
  use ControlServer.DataCase

  alias KubeResources.Notebooks
  import KubeResources.ControlServerFactory

  require Logger

  describe "ML BaseService" do
    test "Can materialize notebooks" do
      assert map_size(Notebooks.materialize(%{})) >= 1
    end

    test "can materialize with a notebook" do
      _notebook = insert(:notebook)

      # Should include the service
      # account, the statefulsets, and the service.
      assert map_size(Notebooks.materialize(%{})) >= 3
    end
  end
end
