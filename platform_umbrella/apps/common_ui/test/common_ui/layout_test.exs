defmodule CommonUI.LayoutTest do
  use CommonUI.ConnCase

  alias CommonUI.Layout

  @endpoint Endpoint

  test "Layout can render iframe" do
    html =
      render_surface do
        ~F"""
        <Layout container_type={:iframe}>Hello</Layout>
        """
      end

    assert html =~ "flex-1 py-0 px-0 w-full"
    assert html =~ "Hello"
  end
end
