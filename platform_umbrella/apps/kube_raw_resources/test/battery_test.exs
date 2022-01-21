defmodule KubeRawResources.BatteryTest do
  use ExUnit.Case

  alias KubeRawResources.Battery
  alias KubeExt.Hashing

  describe "KubeRawResources works" do
    test "CRD's good" do
      assert Battery.crd(%{})
             |> Enum.zip(Battery.crd(%{}))
             |> Enum.all?(fn {a, b} -> Hashing.get_hash(a) == Hashing.get_hash(b) end)
    end
  end
end
