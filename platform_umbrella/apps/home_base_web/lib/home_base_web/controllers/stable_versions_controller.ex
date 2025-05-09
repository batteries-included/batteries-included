defmodule HomeBaseWeb.StableVersionsController do
  use HomeBaseWeb, :controller

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, _params) do
    {:ok, report} = CommonCore.ET.StableVersionsReport.new()

    conn
    |> put_status(:ok)
    |> put_view(json: HomeBaseWeb.JwtJSON)
    |> render(:show, jwt: CommonCore.JWK.sign_to_control_server(report))
  end
end
