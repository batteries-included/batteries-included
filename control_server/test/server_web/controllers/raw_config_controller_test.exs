defmodule ServerWeb.RawConfigControllerTest do
  use ServerWeb.ConnCase

  alias Server.Configs
  alias Server.Configs.RawConfig

  @create_attrs %{
    content: %{},
    path: "some/path"
  }
  @update_attrs %{
    content: %{},
    path: "some/updated/path"
  }
  @invalid_attrs %{content: nil, path: nil}

  def fixture(:raw_config) do
    {:ok, raw_config} = Configs.create_raw_config(@create_attrs)
    raw_config
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all raw_configs", %{conn: conn} do
      conn = get(conn, Routes.raw_config_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end


  describe "index with data" do
    setup [:create_raw_config]
    test "lists no raw_configs with filter", %{conn: conn} do
      conn = get(conn, Routes.raw_config_path(conn, :index), path: "not/our/path")
      assert json_response(conn, 200)["data"] == []
    end

        test "lists one raw_configs with good filter", %{conn: conn} do
      conn = get(conn, Routes.raw_config_path(conn, :index), path: "some/path")
      assert  [%{"content" => content, "id" => id, "path" => "some/path"}] = json_response(conn, 200)["data"]
    end
  end

  describe "create raw_config" do
    test "renders raw_config when data is valid", %{conn: conn} do
      conn = post(conn, Routes.raw_config_path(conn, :create), raw_config: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.raw_config_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "content" => %{},
               "path" => "some/path"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.raw_config_path(conn, :create), raw_config: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update raw_config" do
    setup [:create_raw_config]

    test "renders raw_config when data is valid", %{
      conn: conn,
      raw_config: %RawConfig{id: id} = raw_config
    } do
      conn =
        put(conn, Routes.raw_config_path(conn, :update, raw_config), raw_config: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.raw_config_path(conn, :show, id))

      assert %{
               "id" => ^id,
               "content" => %{},
               "path" => "some/updated/path"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, raw_config: raw_config} do
      conn =
        put(conn, Routes.raw_config_path(conn, :update, raw_config), raw_config: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete raw_config" do
    setup [:create_raw_config]

    test "deletes chosen raw_config", %{conn: conn, raw_config: raw_config} do
      conn = delete(conn, Routes.raw_config_path(conn, :delete, raw_config))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.raw_config_path(conn, :show, raw_config))
      end
    end
  end

  defp create_raw_config(_) do
    raw_config = fixture(:raw_config)
    %{raw_config: raw_config}
  end
end
