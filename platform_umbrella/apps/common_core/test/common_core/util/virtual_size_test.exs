defmodule CommonCore.Util.VirtualSizeTest do
  use ExUnit.Case, async: true

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory
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
          virtual_size: "custom",
          storage_size: Memory.to_bytes(255, :GB),
          cpu_requested: 600,
          cpu_limits: 700,
          memory_requested: Memory.to_bytes(1, :GB),
          memory_limits: Memory.to_bytes(4, :GB)
        )

      assert VirtualSize.get_virtual_size(cluster) == "custom"
    end
  end

  describe "Works with CommonCore.Notebooks.JupyterLabNotebook" do
    test "returns tiny when there's a preset" do
      notebook = CommonCore.Notebooks.JupyterLabNotebook.new!(virtual_size: "tiny", name: "test")
      assert VirtualSize.get_virtual_size(notebook) == "tiny"
    end
  end
end
