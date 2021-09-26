defmodule KubeResources.BatteryTest do
  use ControlServer.DataCase

  alias KubeResources.Battery
  alias KubeExt.Hashing

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(ControlServer.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(ControlServer.Repo, {:shared, self()})
    :ok
  end

  describe "Battery core services works from the BaseService" do
    test "Can materialize" do
      assert map_size(Battery.materialize(%{})) >= 3
    end

    test "CRD's good" do
      assert Battery.crd(%{})
             |> Enum.zip(Battery.crd(%{}))
             |> Enum.all?(fn {a, b} -> Hashing.get_hash(a) == Hashing.get_hash(b) end)
    end
  end
end
