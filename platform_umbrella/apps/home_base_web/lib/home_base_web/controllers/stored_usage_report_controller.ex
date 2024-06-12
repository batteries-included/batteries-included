defmodule HomeBaseWeb.StoredUsageReportController do
  use HomeBaseWeb, :controller

  alias CommonCore.Installation
  alias HomeBase.CustomerInstalls
  alias HomeBase.ET
  alias HomeBase.ET.StoredUsageReport

  action_fallback HomeBaseWeb.FallbackController

  def create(conn, %{"jwt" => jwt, "installation_id" => install_id}) do
    installation = CustomerInstalls.get_installation!(install_id)
    report = Installation.verify_message!(installation, jwt)

    with {:ok, %StoredUsageReport{} = stored_usage_report} <-
           ET.create_stored_usage_report(%{report: report, installation_id: install_id}) do
      conn
      |> put_status(:created)
      |> render(:show, stored_usage_report: stored_usage_report)
    end
  end
end
