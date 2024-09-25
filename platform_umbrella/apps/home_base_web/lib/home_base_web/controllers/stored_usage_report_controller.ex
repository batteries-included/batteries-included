defmodule HomeBaseWeb.StoredUsageReportController do
  use HomeBaseWeb, :controller

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls
  alias HomeBase.ET
  alias HomeBase.ET.StoredUsageReport

  require Logger

  action_fallback HomeBaseWeb.FallbackController

  def create(conn, %{"jwt" => jwt, "installation_id" => install_id}) do
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

    # At this point we at guaranteed that we don't know thw private key
    # So all reports must be signed from the installation.
    with {:ok, %StoredUsageReport{} = stored_usage_report} <-
           ET.create_stored_usage_report(%{report: report, installation_id: install_id}) do
      conn
      |> put_status(:created)
      |> render(:show, stored_usage_report: stored_usage_report)
    end
  end
end
