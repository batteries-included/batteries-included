defmodule CommonUI.Components.BrandTest do
  use CommonUI.ComponentCase

  import CommonUI.Components.Brand

  test "it renders the logo correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.brand class="some-class" />
      """)

    assert html =~ "Batteries"
    assert html =~ "some-class"
  end
end
