defmodule HomeBaseWeb.StoredProjectSnapshotController do
  use HomeBaseWeb, :controller

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls
  alias HomeBase.Projects
  alias HomeBase.Projects.StoredProjectSnapshot

  require Logger

  action_fallback HomeBaseWeb.FallbackController

  def create(conn, %{"installation_id" => install_id, "jwt" => jwt}) do
    installation = CustomerInstalls.get_installation!(install_id)
    snapshot = Installation.verify_message!(installation, jwt)

    with {:ok, %StoredProjectSnapshot{} = stored_project_snapshot} <-
           Projects.create_stored_project_snapshot(%{snapshot: snapshot, installation_id: install_id}) do
      conn
      |> put_status(:created)
      |> render(:show, stored_project_snapshot: stored_project_snapshot)
    end
  end
end
