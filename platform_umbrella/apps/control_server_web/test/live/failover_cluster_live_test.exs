defmodule ControlServerWeb.RedisInstanceLiveTest do
  use ControlServerWeb.ConnCase

  import ControlServer.RedisFixtures
  import Phoenix.LiveViewTest

  defp create_redis_instance(_) do
    redis_instance = redis_instance_fixture()
    %{redis_instance: redis_instance}
  end

  describe "Index" do
    setup [:create_redis_instance]

    test "lists all redis_instances", %{conn: conn, redis_instance: redis_instance} do
      {:ok, _index_live, html} = live(conn, ~p"/redis")

      assert html =~ "Redis Instances"
      assert html =~ redis_instance.name
    end

    test "links to new cluster form", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/redis")

      index_live
      |> element("a", "New Redis Instance")
      |> render_click()
      |> follow_redirect(conn, ~p"/redis/new")
    end
  end
end
