defmodule HomeBaseWeb.StoredHostReportController do
  use HomeBaseWeb, :controller

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls
  alias HomeBase.ET
  alias HomeBase.ET.StoredHostReport

  require Logger

  action_fallback HomeBaseWeb.FallbackController

  def create(conn, %{"installation_id" => install_id, "jwt" => jwt}) do
    installation = CustomerInstalls.get_installation!(install_id)
    report = Installation.verify_message!(installation, jwt)

    # This will rarely happen. It will only happen for the first
    # report of the installation.
    #
    # Once the installation reported back, we no longer want the
    # private key. Delete it. They showed proof of life.
    if CommonCore.JWK.has_private_key?(installation.control_jwk) do
      {:ok, _} = CustomerInstalls.remove_control_jwk(installation)
      Logger.info("Removed private key for installation #{install_id} this was the first report")
    end

    with {:ok, %StoredHostReport{} = stored_host_report} <-
           ET.create_stored_host_report(%{report: report, installation_id: install_id}) do
      conn
      |> put_status(:created)
      |> render(:show, stored_host_report: stored_host_report)
    end
  end
end
