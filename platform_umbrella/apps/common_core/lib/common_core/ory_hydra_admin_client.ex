defmodule CommonCore.OryHydraAdminClient do
  use Tesla

  require Logger

  plug(Tesla.Middleware.JSON)

  def get_consent_request(base_url, challenge) do
    get_url = "#{base_url}/admin/oauth2/auth/requests/consent"

    case get(Tesla.build_url(get_url, consent_challenge: challenge)) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:error, exception} -> {:error, exception}
      err -> {:error, {:unknown_error, err}}
    end
  end

  def accept_consent(base_url, challenge, consent) do
    accept_url = "#{base_url}/admin/oauth2/auth/requests/consent/accept"
    final_url = Tesla.build_url(accept_url, consent_challenge: challenge)

    case put(final_url, consent) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:error, exception} -> {:error, exception}
      err -> {:error, {:unknown_error, err}}
    end
  end
end
