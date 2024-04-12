defmodule CommonUI.Components.LoaderTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Loader

  describe "loader component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.loader />
      """
    end

    component_snapshot_test "fullscreen" do
      assigns = %{}

      ~H"""
      <.loader fullscreen />
      """
    end
  end
end
