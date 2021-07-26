defmodule CommonUI.ButtonTest do
  use CommonUI.ConnCase

  alias CommonUI.Button

  @endpoint Endpoint

  test "Button can render" do
    html =
      render_surface do
        ~F"""
        <Button>Hello</Button>
        """
      end

    assert html =~ "<button"
  end

  test "Button works with primary" do
    html =
      render_surface do
        ~F"""
        <Button theme={:primary}>Hello</Button>
        """
      end

    assert html =~ "<button"
  end

  test "Button can take in class" do
    html =
      render_surface do
        ~F"""
        <Button theme={:default} class="testunique">Hello</Button>
        """
      end

    assert html =~ "<button"
    assert html =~ "testunique"
  end
end
