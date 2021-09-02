defmodule KubeResources.MLTest do
  use ControlServer.DataCase

  alias KubeResources.ML
  import KubeResources.ControlServerFactory

  require Logger

  describe "ML BaseService" do
    test "Can materialize" do
      assert map_size(ML.materialize(%{})) >= 1
    end

    test "can materialize with a notebook" do
      notebook = insert(:notebook)

      Logger.warning("Notebook => #{inspect(notebook)}")

      # Should include the service
      # account, the statefulsets, and the service.
      assert map_size(ML.materialize(%{})) >= 3
    end
  end
end
