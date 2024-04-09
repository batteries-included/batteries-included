defmodule ControlServerWeb.BackendServiceController do
  use ControlServerWeb, :controller

  alias CommonCore.Backend.Service
  alias ControlServer.Backend

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    backend_services = Backend.list_backend_services()
    render(conn, :index, backend_services: backend_services)
  end

  def create(conn, %{"service" => service_params}) do
    with {:ok, %Service{} = service} <- Backend.create_service(service_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/backend/services/#{service}")
      |> render(:show, service: service)
    end
  end

  def show(conn, %{"id" => id}) do
    service = Backend.get_service!(id)
    render(conn, :show, service: service)
  end

  def update(conn, %{"id" => id, "service" => service_params}) do
    service = Backend.get_service!(id)

    with {:ok, %Service{} = service} <- Backend.update_service(service, service_params) do
      render(conn, :show, service: service)
    end
  end

  def delete(conn, %{"id" => id}) do
    service = Backend.get_service!(id)

    with {:ok, %Service{}} <- Backend.delete_service(service) do
      send_resp(conn, :no_content, "")
    end
  end
end
