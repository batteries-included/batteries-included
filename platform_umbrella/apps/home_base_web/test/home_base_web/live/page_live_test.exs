defmodule HomeBaseWeb.PageLiveTest do
  use HomeBaseWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Get notified when we’re launching"
    assert render(page_live) =~ "Get notified when we’re launching"
  end
end
