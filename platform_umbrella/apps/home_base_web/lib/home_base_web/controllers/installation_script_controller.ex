defmodule HomeBaseWeb.InstallScriptController do
  use HomeBaseWeb, :controller
  use HomeBaseWeb, :verified_routes

  require EEx

  EEx.function_from_file(:defp, :render_install_script, "priv/raw_files/install_script.sh", [:spec_url, :version])

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    script =
      render_install_script(
        get_url(conn, install_id),
        CommonCore.Defaults.Versions.bi_stable_version()
      )

    conn
    |> put_status(:ok)
    |> text(script)
  end

  defp get_url(conn, id) do
    uri =
      conn
      |> request_url()
      |> URI.new!()
      |> Map.put(:path, "/")

    conn
    |> get_req_header("x-forwarded-proto")
    |> List.first(uri.scheme)
    |> then(&Map.put(uri, :scheme, &1))
    |> url(~p'/api/v1/installations/#{id}/spec')
  end
end
