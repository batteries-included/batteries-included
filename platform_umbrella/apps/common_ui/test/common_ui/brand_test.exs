defmodule CommonUI.BrandTest do
  use ComponentCase

  import CommonUI.Brand

  test "it renders the logo correctly" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.logo class="some-class" />
      """)

    assert html =~ "Batteries"
    assert html =~ "some-class"
  end
end
