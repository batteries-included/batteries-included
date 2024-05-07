defmodule CommonUI.Components.DropdownTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Dropdown

  component_snapshot_test "dropdown component" do
    assigns = %{}

    ~H"""
    <.dropdown id="foobar">
      <:trigger>Some trigger</:trigger>

      <.dropdown_link icon={:academic_cap}>Baz</.dropdown_link>
      <.dropdown_hr />
      <.dropdown_link icon={:beaker} selected>Foo</.dropdown_link>
      <.dropdown_link icon={:bug_ant}>Bar</.dropdown_link>
    </.dropdown>
    """
  end
end
