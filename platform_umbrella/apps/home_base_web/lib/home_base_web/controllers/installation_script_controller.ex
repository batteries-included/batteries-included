defmodule HomeBaseWeb.InstallScriptController do
  use HomeBaseWeb, :controller
  use HomeBaseWeb, :verified_routes

  require EEx

  EEx.function_from_file(:defp, :render_install_script, "priv/raw_files/install_script.sh", [:spec_url, :version])

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    script =
      render_install_script(
        url(conn, ~p'/api/v1/installations/#{install_id}/spec'),
        CommonCore.Version.version()
      )

    conn
    |> put_status(:ok)
    |> text(script)
  end
end
