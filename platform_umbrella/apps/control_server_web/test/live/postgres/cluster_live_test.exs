defmodule ControlServerWeb.Postgres.ClusterLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "postgres clusters" do
    test "shows the previously selected virtual_size", %{conn: conn} do
      cluster = insert(:postgres_cluster, virtual_size: "small")

      url = ~s|/postgres/#{cluster.id}/edit|

      conn
      |> start(url)
      |> assert_html(cluster.name)
      |> assert_matches_snapshot(selector: "#postgres_virtual_size")
    end
  end
end
