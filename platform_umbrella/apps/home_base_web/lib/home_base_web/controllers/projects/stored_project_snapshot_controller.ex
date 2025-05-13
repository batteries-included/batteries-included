defmodule HomeBaseWeb.StoredProjectSnapshotController do
  use HomeBaseWeb, :controller

  alias HomeBase.CustomerInstalls
  alias HomeBase.Projects
  alias HomeBase.Projects.StoredProjectSnapshot

  require Logger

  @dialyzer {:nowarn_function, create: 2}

  action_fallback HomeBaseWeb.FallbackController

  def create(conn, %{"installation_id" => install_id, "jwt" => jwt}) do
    with %{} = installation <- CustomerInstalls.get_installation!(install_id),
         snapshot = CommonCore.JWK.decrypt_from_control_server!(installation.control_jwk, jwt),
         {:ok, %StoredProjectSnapshot{} = stored_project_snapshot} <-
           Projects.create_stored_project_snapshot(%{snapshot: snapshot, installation_id: installation.id}) do
      conn
      |> put_status(:created)
      |> render(:show, payload: stored_project_snapshot)
    end
  end

  def index(conn, %{"installation_id" => install_id}) do
    installation = CustomerInstalls.get_installation!(install_id)

    payload = %{snapshots: Projects.snapshots_for(installation), captured: DateTime.utc_now()}

    conn
    |> put_status(:ok)
    |> put_view(json: HomeBaseWeb.JwtJSON)
    |> render(:show, jwt: CommonCore.JWK.encrypt_to_control_server(installation.control_jwk, payload))
  end

  def show(conn, %{"installation_id" => install_id, "id" => id}) do
    with %{} = installation <- CustomerInstalls.get_installation!(install_id),
         {:ok, %StoredProjectSnapshot{} = stored_project_snapshot} <-
           Projects.get_stored_project_snapshot(installation, id) do
      conn
      |> put_status(:ok)
      |> put_view(json: HomeBaseWeb.JwtJSON)
      |> render(:show, jwt: CommonCore.JWK.encrypt_to_control_server(installation.control_jwk, stored_project_snapshot))
    end
  end
end
