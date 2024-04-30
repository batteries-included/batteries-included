defmodule CommonUI.Components.DropdownTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Dropdown

  component_snapshot_test "dropdown component" do
    assigns = %{}

    ~H"""
    <.dropdown id="foobar">
      <:trigger>Some trigger</:trigger>
      <:item icon={:academic_cap}>Baz</:item>
      <:item icon={:beaker} selected>Foo</:item>
      <:item icon={:bug_ant}>Bar</:item>
    </.dropdown>
    """
  end
end
