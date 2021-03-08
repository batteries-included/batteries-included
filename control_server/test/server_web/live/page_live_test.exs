defmodule ServerWeb.PageLiveTest do
  use ServerWeb.ConnCase
  alias Server.Configs.Defaults

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    Defaults.create_all()
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Hello Batteries"
    assert render(page_live) =~ "Hello Batteries"
  end
end
