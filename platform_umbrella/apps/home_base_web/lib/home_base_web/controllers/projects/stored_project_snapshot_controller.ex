defmodule HomeBaseWeb.StoredProjectSnapshotController do
  use HomeBaseWeb, :controller

  alias HomeBase.CustomerInstalls
  alias HomeBase.Projects
  alias HomeBase.Projects.StoredProjectSnapshot

  require Logger

  @dialyzer {:nowarn_function, create: 2}

  action_fallback HomeBaseWeb.FallbackController

  def create(conn, %{"installation_id" => install_id, "jwt" => jwt}) do
    installation = CustomerInstalls.get_installation!(install_id)
    snapshot = CommonCore.JWK.decrypt(installation.control_jwk, jwt)

    with {:ok, %StoredProjectSnapshot{} = stored_project_snapshot} <-
           Projects.create_stored_project_snapshot(%{snapshot: snapshot, installation_id: install_id}) do
      conn
      |> put_status(:created)
      |> render(:show, stored_project_snapshot: stored_project_snapshot)
    end
  end

  def index(conn, %{"installation_id" => install_id}) do
    installation = CustomerInstalls.get_installation!(install_id)

    payload = %{snapshots: Projects.snapshots_for(installation), captured: DateTime.utc_now()}

    conn
    |> put_status(:ok)
    |> render(:index, payload: CommonCore.JWK.encrypt(installation.control_jwk, payload))
  end
end
