defmodule HomeBaseWeb.StableVersionController do
  use HomeBaseWeb, :controller

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, _params) do
    conn
    |> put_status(:ok)
    |> put_view(json: HomeBaseWeb.JwtJSON)
    |> render(:show, jwt: CommonCore.JWK.sign(versions()))
  end

  defp versions do
    %{
      control_server: CommonCore.Version.version(),
      exp: DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_unix()
    }
  end
end
