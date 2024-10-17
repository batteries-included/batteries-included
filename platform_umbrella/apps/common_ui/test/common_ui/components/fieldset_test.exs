defmodule CommonUI.Components.FieldsetTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Fieldset

  component_snapshot_test "default fieldset component" do
    assigns = %{}

    ~H"""
    <.fieldset id="foo" title="Foo">Bar</.fieldset>
    """
  end

  component_snapshot_test "responsive fieldset component" do
    assigns = %{}

    ~H"""
    <.fieldset id="foo" responsive>
      Foobar
      <:actions>Actions</:actions>
    </.fieldset>
    """
  end
end
