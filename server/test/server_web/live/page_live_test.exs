defmodule ServerWeb.PageLiveTest do
  use ServerWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Hello Batteries"
    assert render(page_live) =~ "Hello Batteries"
  end
end
