defmodule HomeBaseWeb.InstallSpecController do
  use HomeBaseWeb, :controller

  alias HomeBase.CustomerInstalls

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    installation = CustomerInstalls.get_installation!(install_id)
    {:ok, report} = CommonCore.InstallSpec.new(installation)

    conn
    |> put_status(:ok)
    |> put_view(json: HomeBaseWeb.JwtJSON)
    |> render(:show, jwt: CommonCore.JWK.sign(report))
  end
end
