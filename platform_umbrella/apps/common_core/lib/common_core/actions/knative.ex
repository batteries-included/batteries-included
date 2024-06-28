defmodule CommonCore.Actions.Knative do
  @moduledoc false
  @behaviour CommonCore.Actions.ActionGenerator

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Actions.SSOClient
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Knative.Service
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KeycloakSummary
  alias CommonCore.StateSummary.URLs

  @spec materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t() | nil)
  def materialize(%SystemBattery{} = _system_battery, %StateSummary{} = state_summary) do
    ensure_knative_realms(state_summary) ++ ensure_knative_clients(state_summary)
  end

  # make sure we have a realm for every realm that knative services are using
  defp ensure_knative_realms(%StateSummary{keycloak_state: key_state, knative_services: services} = _state_summary) do
    services
    |> Enum.filter(&Service.sso_configured_properly?/1)
    |> MapSet.new(& &1.keycloak_realm)
    |> Enum.map(fn realm ->
      if KeycloakSummary.realm_member?(key_state, realm) do
        nil
      else
        %FreshGeneratedAction{
          action: :create,
          type: :realm,
          realm: nil,
          value: %{
            realm: realm,
            displayName: "Batteries Included - #{realm}",
            rememberMe: true,
            social: false,
            enabled: true
          }
        }
      end
    end)
  end

  defp ensure_knative_clients(%StateSummary{keycloak_state: key_state, knative_services: services} = state_summary) do
    services
    |> Enum.filter(&Service.sso_configured_properly?/1)
    |> Enum.map(fn %{keycloak_realm: realm, name: name} = service ->
      id = name |> Base.encode16() |> String.slice(0..35)
      url = URLs.knative_url(state_summary, service)
      client = SSOClient.default_client(id, name, URI.to_string(url))
      SSOClient.determine_action(key_state, realm, client, SSOClient.default_client_fields())
    end)
  end
end
