defmodule CommonCore.Util.VirtualSizeTest do
  use ExUnit.Case, async: true

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.VirtualSize

  describe "Works with CommonCore.Postgres.Cluster" do
    test "returns tiny when there's a tiny preset" do
      cluster = Cluster.new!(virtual_size: "tiny", name: "test")

      assert VirtualSize.get_virtual_size(cluster) == "tiny"
    end

    test "custom sizes work" do
      cluster =
        Cluster.new!(
          name: "test",
          storage_size: 1_000_000_003,
          cpu_requested: 600,
          cpu_limits: 700,
          memory_requested: 1_000_000_005,
          memory_limits: 1_000_000_006
        )

      assert VirtualSize.get_virtual_size(cluster) == "custom"
    end
  end
end
