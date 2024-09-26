defmodule HomeBaseWeb.InstallScriptController do
  use HomeBaseWeb, :controller
  use HomeBaseWeb, :verified_routes

  import CommonUI.UrlHelpers

  require EEx

  EEx.function_from_file(:defp, :render_install_script, "priv/raw_files/install_script.sh", [:spec_url, :version])

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    url = conn |> get_uri_from_conn() |> url(~p'/api/v1/installations/#{install_id}/spec')
    bi_version = CommonCore.Defaults.Versions.bi_stable_version()

    script = render_install_script(url, bi_version)

    conn
    |> put_status(:ok)
    |> text(script)
  end
end
