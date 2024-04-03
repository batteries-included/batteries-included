defmodule ControlServerWeb.StaleIndexTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  test "render list of stale", %{conn: conn} do
    conn
    |> start(~p|/stale|)
    |> assert_html("Stale Deleter Queue")
  end
end
