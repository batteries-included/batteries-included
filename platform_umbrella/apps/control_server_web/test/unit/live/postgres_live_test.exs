defmodule ControlServerWeb.PostgresLiveTest do
  use Heyya.LiveTest
  use ControlServerWeb.ConnCase

  test "render list postgres", %{conn: conn} do
    conn
    |> start(~p|/postgres|)
    |> assert_html("Postgres Clusters")
    |> assert_html("Name")
    |> assert_html("Type")
    |> click("a", "New Cluster")
    |> follow(~p|/postgres/new|)
  end
end
