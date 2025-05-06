defmodule HomeBaseWeb.InstallSpecController do
  use HomeBaseWeb, :controller

  alias HomeBase.CustomerInstalls

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    installation = CustomerInstalls.get_installation!(install_id)

    if CommonCore.JWK.has_private_key?(installation.control_jwk) do
      {:ok, report} = CommonCore.InstallSpec.new(installation)

      conn
      |> put_status(:ok)
      |> put_view(json: HomeBaseWeb.JwtJSON)
      |> render(:show, jwt: CommonCore.JWK.sign_to_control_server(report))
    else
      conn
      |> put_status(:bad_request)
      |> put_view(json: HomeBaseWeb.ErrorJSON)
      |> render(:error, %{error: "Private key not found"})
      |> halt()
    end
  end
end
