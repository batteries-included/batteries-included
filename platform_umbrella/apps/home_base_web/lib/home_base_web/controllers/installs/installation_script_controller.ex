defmodule HomeBaseWeb.InstallScriptController do
  use HomeBaseWeb, :controller
  use HomeBaseWeb, :verified_routes

  import CommonUI.UrlHelpers

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    url = conn |> get_uri_from_conn() |> url(~p'/api/v1/installations/#{install_id}/spec')

    conn
    |> put_status(:ok)
    |> text(HomeBase.Scripts.start_install(url))
  end
end
