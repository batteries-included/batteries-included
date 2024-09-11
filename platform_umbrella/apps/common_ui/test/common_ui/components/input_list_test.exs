defmodule CommonUI.Components.InputListTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Input
  import CommonUI.Components.InputList

  describe "input list component" do
    component_snapshot_test "default" do
      field = %Phoenix.HTML.FormField{
        id: "foobar",
        errors: [],
        field: "foo",
        name: "foo",
        value: ["bar"],
        form: %Phoenix.HTML.Form{}
      }

      assigns = %{field: field}

      ~H"""
      <.input_list :let={f} field={@field} label="Foobar" add_label="Add an item">
        <.input field={f} />
      </.input_list>
      """
    end
  end
end
