defmodule ControlServerWeb.StaleIndexTest do
  use Heyya.LiveTest
  use ControlServerWeb.ConnCase

  test "render list of stale", %{conn: conn} do
    start(conn, ~p|/stale|)
    |> assert_html("Stale Deleter Queue")
    |> assert_html("Kind")
    |> assert_html("Name")
    |> assert_html("Namespace")
  end
end
