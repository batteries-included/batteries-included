defmodule ControlServerWeb.LayoutTest do
  use ControlServerWeb.ConnCase

  import Phoenix.Component, except: [link: 1]
  import Phoenix.LiveViewTest
  import ControlServerWeb.MenuLayout

  test "Layout can render iframe" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.menu_layout container_type={:iframe}>
        Hello
      </.menu_layout>
      """)

    assert html =~ "flex-1 py-0 px-0 w-full"
    assert html =~ "Hello"
  end
end
