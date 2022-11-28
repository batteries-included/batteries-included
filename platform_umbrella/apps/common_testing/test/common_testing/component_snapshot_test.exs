defmodule CommonTesting.ComponentSnapshotTestTest do
  use CommonTesting.ComponentSnapshotTest

  component_snapshot_test "Header test" do
    assigns = %{}

    ~H"""
    <Header.simple>Testing</Header.simple>
    """
  end
end
