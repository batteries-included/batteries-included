defmodule HomeBaseWeb.InstallationStatusContoller do
  @moduledoc false

  use HomeBaseWeb, :controller

  alias CommonCore.ET.InstallStatus
  alias HomeBase.CustomerInstalls

  action_fallback HomeBaseWeb.FallbackController

  def show(conn, %{"installation_id" => install_id}) do
    # For now just make sure the installation exists
    installation = CustomerInstalls.get_installation!(install_id)
    # One hour when everyone comes back in 9 minutes seems good
    # Adjust when needed
    exp =
      DateTime.utc_now()
      |> DateTime.add(1, :hour)
      |> DateTime.to_unix()

    # Everything is ok
    status = :ok

    install_status =
      InstallStatus.new!(
        status: status,
        message: message(status, Enum.random(0..3)),
        iss: installation.id,
        exp: exp
      )

    conn
    |> put_status(:ok)
    |> put_view(json: HomeBaseWeb.JwtJSON)
    |> render(:show, jwt: CommonCore.JWK.sign(install_status))
  end

  # Like the status says we're ok, not great, not bad, just ok.
  #
  # These are never seen but are burried in JWTs as some noise.
  defp message(:ok, 0), do: "The cake is a lie."
  defp message(:ok, 1), do: "Idiocracy (2006) was not supposed to be a documentary."
  defp message(:ok, 2), do: "We've built economies on growth and now can't afford to stop growing."
  defp message(:ok, _), do: "Cyberpunk was supposed to be a dystopian vision of the future, not a goal."
end
