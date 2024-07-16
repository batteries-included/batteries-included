defmodule ControlServerWeb.TraditionalServicesController do
  use ControlServerWeb, :controller

  alias CommonCore.TraditionalServices.Service
  alias ControlServer.TraditionalServices

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    traditional_services = TraditionalServices.list_traditional_services()
    render(conn, :index, traditional_services: traditional_services)
  end

  def create(conn, %{"service" => service_params}) do
    with {:ok, %Service{} = service} <- TraditionalServices.create_service(service_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/traditional_services/#{service}")
      |> render(:show, service: service)
    end
  end

  def show(conn, %{"id" => id}) do
    service = TraditionalServices.get_service!(id)
    render(conn, :show, service: service)
  end

  def update(conn, %{"id" => id, "service" => service_params}) do
    service = TraditionalServices.get_service!(id)

    with {:ok, %Service{} = service} <- TraditionalServices.update_service(service, service_params) do
      render(conn, :show, service: service)
    end
  end

  def delete(conn, %{"id" => id}) do
    service = TraditionalServices.get_service!(id)

    with {:ok, %Service{}} <- TraditionalServices.delete_service(service) do
      send_resp(conn, :no_content, "")
    end
  end
end
