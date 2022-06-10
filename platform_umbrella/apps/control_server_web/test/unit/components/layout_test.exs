defmodule ControlServerWeb.LayoutTest do
  use ControlServerWeb.ConnCase

  import ControlServerWeb.Layout

  test "Layout can render iframe" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.layout container_type={:iframe}>
        Hello
      </.layout>
      """)

    assert html =~ "flex-1 py-0 px-0 w-full"
    assert html =~ "Hello"
  end
end
