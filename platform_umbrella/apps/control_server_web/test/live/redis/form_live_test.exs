defmodule ControlServerWeb.Redis.RedisFormLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "the new page works" do
    test "shows the new page", %{conn: conn} do
      url = ~s|/redis/new|

      params = %{name: "test-redis"}

      conn
      |> start(url)
      |> assert_html("New Redis Instance")
      |> form("#redis_instance-form", %{"redis_instance" => params})
      |> assert_matches_snapshot(selector: "input[name='redis_instance[name]']", name: "input__redis_instance_name")
    end

    test "can create a new instance", %{conn: conn} do
      url = ~s|/redis/new|

      params =
        :redis_instance
        |> params_for()
        |> Map.drop(~w(id type num_instances)a)

      conn
      |> start(url)
      |> submit_form("#redis_instance-form", %{"redis_instance" => params})
      |> follow()

      instances = ControlServer.Redis.list_redis_instances()

      assert Enum.any?(instances, fn instance ->
               instance.name == params.name
             end)
    end
  end
end
