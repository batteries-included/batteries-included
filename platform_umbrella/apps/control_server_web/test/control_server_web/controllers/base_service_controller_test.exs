defmodule ControlServerWeb.BaseServiceControllerTest do
  use ControlServerWeb.ConnCase

  alias ControlServer.Services.BaseService

  import ControlServer.Factory

  @create_attrs %{
    is_active: true,
    root_path: "/some/root/path",
    config: %{},
    service_type: :prometheus
  }
  @update_attrs %{
    is_active: false,
    root_path: "some updated root_path",
    config: %{},
    service_type: "prometheus"
  }
  @invalid_attrs %{is_active: nil, root_path: nil, config: nil, service_type: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create base_service" do
    test "renders base_service when data is valid", %{conn: conn} do
      conn = post(conn, Routes.base_service_path(conn, :create), base_service: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.base_service_path(conn, :show, id))

      assert %{
               "id" => _id,
               "is_active" => true,
               "service_type" => "prometheus",
               "root_path" => "/some/root/path",
               "config" => %{}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.base_service_path(conn, :create), base_service: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update base_service" do
    setup [:create_base_service]

    test "renders base_service when data is valid", %{
      conn: conn,
      base_service: %BaseService{id: id} = base_service
    } do
      conn =
        put(conn, Routes.base_service_path(conn, :update, base_service),
          base_service: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.base_service_path(conn, :show, id))

      assert %{
               "id" => _id,
               "is_active" => false,
               "root_path" => "some updated root_path",
               "config" => %{}
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, base_service: base_service} do
      conn =
        put(conn, Routes.base_service_path(conn, :update, base_service),
          base_service: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete base_service" do
    setup [:create_base_service]

    test "deletes chosen base_service", %{conn: conn, base_service: base_service} do
      conn = delete(conn, Routes.base_service_path(conn, :delete, base_service))
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, Routes.base_service_path(conn, :show, base_service))
      end)
    end
  end

  defp create_base_service(_) do
    base_service = insert(:base_service)
    %{base_service: base_service}
  end
end
