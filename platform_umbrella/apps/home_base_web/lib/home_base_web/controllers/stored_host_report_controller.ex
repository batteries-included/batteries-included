defmodule HomeBaseWeb.StoredHostReportController do
  use HomeBaseWeb, :controller

  alias HomeBase.ET
  alias HomeBase.ET.StoredHostReport

  action_fallback HomeBaseWeb.FallbackController

  def create(conn, %{"host_report" => report, "installation_id" => install_id}) do
    with {:ok, %StoredHostReport{} = stored_host_report} <-
           ET.create_stored_host_report(%{report: report, installation_id: install_id}) do
      conn
      |> put_status(:created)
      |> render(:show, stored_host_report: stored_host_report)
    end
  end
end
