defmodule ControlServerWeb.TraditionalServicesControllerTest do
  use ControlServerWeb.ConnCase

  import ControlServer.TraditionalServicesFixtures

  alias CommonCore.TraditionalServices.Service

  @create_attrs %{
    name: "some-name",
    containers: [],
    init_containers: [],
    env_values: []
  }
  @update_attrs %{
    name: "some-updated-name",
    containers: [],
    init_containers: [],
    env_values: []
  }
  @invalid_attrs %{name: nil, containers: nil, init_containers: nil, env_values: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all traditional_services", %{conn: conn} do
      conn = get(conn, ~p"/api/traditional_services")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create service" do
    test "renders service when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/traditional_services", service: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/traditional_services/#{id}")

      assert %{
               "id" => ^id,
               "containers" => [],
               "env_values" => [],
               "init_containers" => [],
               "name" => "some-name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/traditional_services", service: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update service" do
    setup [:create_service]

    test "renders service when data is valid", %{conn: conn, service: %Service{id: id} = service} do
      conn = put(conn, ~p"/api/traditional_services/#{service}", service: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/traditional_services/#{id}")

      assert %{
               "id" => ^id,
               "containers" => [],
               "env_values" => [],
               "init_containers" => [],
               "name" => "some-updated-name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, service: service} do
      conn = put(conn, ~p"/api/traditional_services/#{service}", service: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete service" do
    setup [:create_service]

    test "deletes chosen service", %{conn: conn, service: service} do
      conn = delete(conn, ~p"/api/traditional_services/#{service}")
      assert response(conn, 204)

      assert_error_sent(404, fn ->
        get(conn, ~p"/api/traditional_services/#{service}")
      end)
    end
  end

  defp create_service(_) do
    service = service_fixture()
    %{service: service}
  end
end
