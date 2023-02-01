defmodule ControlServerWeb.OryHydraController do
  use ControlServerWeb, :controller

  import KubeServices.SystemState.SummaryHosts
  import CommonCore.OryHydraAdminClient
  import CommonCore.OryKratosAdminClient

  action_fallback(ControlServerWeb.FallbackController)

  def consent(conn, %{"consent_challenge" => consent_challenge} = _params) do
    hydra_base_url = "http://#{hydra_admin_host()}"

    {:ok, consent_request} = get_consent_request(hydra_base_url, consent_challenge)
    consent = to_consent(consent_request, to_session(consent_request))
    {:ok, accept_response} = accept_consent(hydra_base_url, consent_challenge, consent)

    redirect(conn, external: Map.get(accept_response, "redirect_to", "/"))
  end

  defp to_session(%{"subject" => subject} = _consent_request)
       when is_binary(subject) and subject != "" do
    kratos_base_url = "http://#{kratos_admin_host()}"

    with {:ok, identity} <- get_identity(kratos_base_url, subject) do
      email = get_in(identity, [Access.key("traits", %{}), Access.key("email", nil)])
      %{"access_token" => %{"email" => email}, "id_token" => %{"email" => email}}
    end
  end

  defp to_session(_consent_request), do: nil

  defp to_consent(consent_request, session) do
    %{}
    |> Map.put("grant_scope", Map.get(consent_request, "requested_scope", []))
    |> Map.put(
      "grant_access_token_audience",
      Map.get(consent_request, "requested_access_token_audience", [])
    )
    |> Map.put("remember", true)
    |> Map.put("remember_for", 0)
    |> add_session(session)
  end

  defp add_session(consent, nil = _session), do: consent
  defp add_session(consent, %{} = session) when %{} == session, do: consent
  defp add_session(consent, session), do: Map.put(consent, "session", session)
end
