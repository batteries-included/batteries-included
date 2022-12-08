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

    assert html =~ "flex-1 pb-16 pt-0 px-0"
    assert html =~ "Hello"
  end

  test "Layout can render default" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.menu_layout container_type={:default}>
        Hello
      </.menu_layout>
      """)

    assert html =~ "flex-1 max-w-full sm:px-6 lg:px-8 pt-10 pb-16"
    assert html =~ "Hello"
  end
end
