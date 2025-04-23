defmodule ControlServerWeb.Redis.ShowLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "The show page for redis" do
    test "can show an normal instance", %{conn: conn} do
      redis_instance = insert(:redis_instance)

      url = ~s|/redis/#{redis_instance.id}/show|

      conn
      |> start(url)
      |> assert_html("Redis Instance")
      |> assert_html(redis_instance.name)
    end
  end
end
