defmodule ControlServerWeb.BaseServiceController do
  use ControlServerWeb, :controller

  alias ControlServer.Services
  alias ControlServer.Services.BaseService

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    base_services = Services.list_base_services()
    render(conn, "index.json", base_services: base_services)
  end

  def create(conn, %{"base_service" => base_service_params}) do
    with {:ok, %BaseService{} = base_service} <- Services.create_base_service(base_service_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.base_service_path(conn, :show, base_service))
      |> render("show.json", base_service: base_service)
    end
  end

  def show(conn, %{"id" => id}) do
    base_service = Services.get_base_service!(id)
    render(conn, "show.json", base_service: base_service)
  end

  def update(conn, %{"id" => id, "base_service" => base_service_params}) do
    base_service = Services.get_base_service!(id)

    with {:ok, %BaseService{} = base_service} <-
           Services.update_base_service(base_service, base_service_params) do
      render(conn, "show.json", base_service: base_service)
    end
  end

  def delete(conn, %{"id" => id}) do
    base_service = Services.get_base_service!(id)

    with {:ok, %BaseService{}} <- Services.delete_base_service(base_service) do
      send_resp(conn, :no_content, "")
    end
  end
end
