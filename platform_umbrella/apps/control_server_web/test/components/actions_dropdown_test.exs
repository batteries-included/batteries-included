defmodule ControlServerWeb.Components.ActionsDropdownTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Dropdown
  import ControlServerWeb.ActionsDropdown

  describe "actions_dropdown/1" do
    component_snapshot_test "renders actions dropdown with default content" do
      assigns = %{}

      ~H"""
      <.actions_dropdown id="test-dropdown">
        <.dropdown_link navigate="/" icon={:pencil}>
          Edit
        </.dropdown_link>

        <.dropdown_button icon={:trash} phx-click="delete">
          Delete
        </.dropdown_button>
      </.actions_dropdown>
      """
    end
  end
end
