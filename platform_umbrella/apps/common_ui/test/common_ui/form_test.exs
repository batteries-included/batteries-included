defmodule CommonUI.FormTest do
  use ComponentCase

  import CommonUI.Form

  describe "editable_field" do
    test "it renders" do
      assigns = %{form: to_form(%{}, as: :user)}

      html =
        rendered_to_string(~H"""
        <.form for={@form}>
          <.editable_field
            field_attrs={
              %{
                field: @form[:test],
                label: "My label",
                "phx-change": "on_change"
              }
            }
            editing?={false}
            toggle_event_target="1"
            toggle_event="toggle"
            value_when_not_editing="Not editing"
          />
        </.form>
        """)

      assert html =~ "My label"
      assert html =~ "on_change"
      assert html =~ "Not editing"
    end
  end
end
