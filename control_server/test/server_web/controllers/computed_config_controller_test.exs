defmodule ServerWeb.ComputedConfigControllerTest do
  use ServerWeb.ConnCase

  import Server.Factory

  alias Server.Configs.Defaults

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show" do
    test "get a good path", %{conn: conn} do
      {:ok, _} = Defaults.create_all()

      route = Routes.computed_config_path(conn, :show, ["running_set"])

      conn = get(conn, route)

      assert json_response(conn, 200)["data"] == %{
               "content" => %{"monitoring" => false},
               "path" => "/running_set"
             }
    end
  end
end
