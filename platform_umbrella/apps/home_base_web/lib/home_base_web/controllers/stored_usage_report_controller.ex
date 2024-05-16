defmodule HomeBaseWeb.StoredUsageReportController do
  use HomeBaseWeb, :controller

  alias HomeBase.ET
  alias HomeBase.ET.StoredUsageReport

  action_fallback HomeBaseWeb.FallbackController

  def create(conn, %{"usage_report" => report, "installation_id" => install_id}) do
    with {:ok, %StoredUsageReport{} = stored_usage_report} <-
           ET.create_stored_usage_report(%{report: report, installation_id: install_id}) do
      conn
      |> put_status(:created)
      |> render(:show, stored_usage_report: stored_usage_report)
    end
  end
end
