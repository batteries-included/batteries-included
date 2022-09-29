defmodule CommonUI.LayoutTest do
  use ExUnit.Case

  import Phoenix.Component, except: [link: 1]
  import Phoenix.LiveViewTest
  import CommonUI.Layout

  test "Layout can render iframe" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.layout container_type={:iframe}>
        <:title>Test Title</:title>
        <:main_menu>Empty Menu</:main_menu>
        Hello World
      </.layout>
      """)

    assert html =~ "flex-1 py-0 px-0 w-full"
    assert html =~ "Hello World"
    assert html =~ "Test Title"
    assert html =~ "Empty Menu"
  end
end
