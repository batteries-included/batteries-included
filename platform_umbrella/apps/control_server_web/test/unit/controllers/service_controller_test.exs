defmodule ControlServerWeb.KNativeServiceControllerTest do
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias CommonCore.Knative.Service

  @invalid_attrs %{name: "__test_bad_name", rollout_duration: nil, oauth2_proxy: nil, kube_internal: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all services", %{conn: conn} do
      conn = get(conn, ~p"/api/knative/services")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create service" do
    test "renders service when data is valid", %{conn: conn} do
      create_attrs = params_for(:knative_service, name: "some-name")
      conn = post(conn, ~p"/api/knative/services", service: create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/knative/services/#{id}")

      assert %{
               "id" => ^id,
               "kube_internal" => _,
               "name" => "some-name",
               "oauth2_proxy" => _,
               "rollout_duration" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/knative/services", service: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update service" do
    setup [:create_service]

    test "renders service when data is valid", %{conn: conn, service: %Service{id: id} = service} do
      update_attrs = params_for(:knative_service, name: "another-updated-name")
      conn = put(conn, ~p"/api/knative/services/#{service}", service: update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/knative/services/#{id}")

      assert %{
               "id" => ^id,
               "kube_internal" => _,
               "name" => "another-updated-name",
               "oauth2_proxy" => _,
               "rollout_duration" => _
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, service: service} do
      conn = put(conn, ~p"/api/knative/services/#{service}", service: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete service" do
    setup [:create_service]

    test "deletes chosen service", %{conn: conn, service: service} do
      conn = delete(conn, ~p"/api/knative/services/#{service}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/knative/services/#{service}")
      end
    end
  end

  defp create_service(_) do
    service = insert(:knative_service)
    %{service: service}
  end
end
