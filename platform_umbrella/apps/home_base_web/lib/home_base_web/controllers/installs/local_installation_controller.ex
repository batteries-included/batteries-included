defmodule HomeBaseWeb.LocalInstallationController do
  use HomeBaseWeb, :controller

  alias HomeBase.CustomerInstalls

  def create(conn, _params) do
    local_installation = CustomerInstalls.create_local_installation!()

    conn
    |> put_status(:created)
    |> put_view(json: HomeBaseWeb.JwtJSON)
    |> render(:show, jwt: CommonCore.JWK.sign_to_control_server(local_installation))
  end
end
