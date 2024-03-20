defmodule ControlServerWeb.ServiceController do
  use ControlServerWeb, :controller

  alias CommonCore.Knative.Service
  alias ControlServer.Knative

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    services = Knative.list_services()
    render(conn, :index, services: services)
  end

  def create(conn, %{"service" => service_params}) do
    with {:ok, %Service{} = service} <- Knative.create_service(service_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/knative/services/#{service}")
      |> render(:show, service: service)
    end
  end

  def show(conn, %{"id" => id}) do
    service = Knative.get_service!(id)
    render(conn, :show, service: service)
  end

  def update(conn, %{"id" => id, "service" => service_params}) do
    service = Knative.get_service!(id)

    with {:ok, %Service{} = service} <- Knative.update_service(service, service_params) do
      render(conn, :show, service: service)
    end
  end

  def delete(conn, %{"id" => id}) do
    service = Knative.get_service!(id)

    with {:ok, %Service{}} <- Knative.delete_service(service) do
      send_resp(conn, :no_content, "")
    end
  end
end
