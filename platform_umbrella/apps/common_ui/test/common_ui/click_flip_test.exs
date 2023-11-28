defmodule CommonUI.ClickFlipTest do
  use Heyya.SnapshotTest

  import CommonUI.ClickFlip

  describe "click_flip" do
    component_snapshot_test "click_flip" do
      assigns = %{}

      ~H"""
      <.click_flip>
        Main Content Here
        <:hidden>
          This conent will only be shown when clicked
        </:hidden>
      </.click_flip>
      """
    end

    component_snapshot_test "with toolpip" do
      assigns = %{}

      ~H"""
      <.click_flip tooltip="Click to edit" id="test-click-flip-with-id">
        Main
        <:hidden>
          Form Field Here
        </:hidden>
      </.click_flip>
      """
    end

    component_snapshot_test "with class" do
      assigns = %{}

      ~H"""
      <.click_flip class="p-4" content_class="p-8">
        Look at the room here
        <:hidden>
          Dunno what to say, it's click to edit
        </:hidden>
      </.click_flip>
      """
    end
  end
end
