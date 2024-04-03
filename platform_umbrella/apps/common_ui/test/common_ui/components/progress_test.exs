defmodule CommonUI.Components.ProgressTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Progress

  describe "progress component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.progress current={4} total={10} />
      """
    end

    component_snapshot_test "stepped variant" do
      assigns = %{}

      ~H"""
      <.progress current={4} total={10} variant="stepped" />
      """
    end
  end
end
