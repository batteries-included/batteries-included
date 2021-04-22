defmodule ControlServerWeb.PageLiveTest do
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Batteries Included"
    assert render(page_live) =~ "Batteries Included"
  end
end
