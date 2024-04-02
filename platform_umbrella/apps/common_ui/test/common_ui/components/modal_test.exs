defmodule CommonUI.Components.ModalTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.Modal

  alias Phoenix.LiveView.JS

  describe "modal component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.modal id="modal">
        <:title>Title</:title>
        <p>This is a modal.</p>
      </.modal>
      """
    end

    component_snapshot_test "shown" do
      assigns = %{}

      ~H"""
      <.modal id="modal" show>
        <:title>Title</:title>
        <p>This is a modal.</p>
      </.modal>
      """
    end

    component_snapshot_test "with actions" do
      assigns = %{}

      ~H"""
      <.modal id="modal" on_cancel={JS.push("test")}>
        <:title>Title</:title>
        <:actions cancel="Cancel">
          <button>Confirm</button>
        </:actions>

        <p>This is a modal.</p>
      </.modal>
      """
    end
  end
end
