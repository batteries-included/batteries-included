defmodule HomeBaseWeb.InstallScriptController do
  use HomeBaseWeb, :controller
  use HomeBaseWeb, :verified_routes

  require EEx

  EEx.function_from_file(:defp, :render_install_script, "priv/raw_files/install_script.sh", [:spec_url])

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    script =
      conn
      |> url(~p'/api/v1/installations/#{install_id}/spec')
      |> render_install_script()

    conn
    |> put_status(:ok)
    |> text(script)
  end
end
