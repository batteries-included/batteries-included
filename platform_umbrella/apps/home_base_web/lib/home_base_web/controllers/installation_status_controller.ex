defmodule HomeBaseWeb.InstallationStatusContoller do
  @moduledoc false

  use HomeBaseWeb, :controller

  alias CommonCore.ET.InstallStatus
  alias HomeBase.CustomerInstalls

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    # For now just make sure the installation exists
    _installation = CustomerInstalls.get_installation!(install_id)
    # Everything is ok
    status = InstallStatus.new!(status: :ok, message: "Installation is ok")

    conn
    |> put_status(:ok)
    |> put_view(json: HomeBaseWeb.InstallationStatusJSON)
    |> render(:show, jwt: CommonCore.JWK.sign(status))
  end
end
