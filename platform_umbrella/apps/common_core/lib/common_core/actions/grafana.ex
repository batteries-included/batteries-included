defmodule CommonCore.Actions.Grafana do
  @moduledoc false
  @behaviour CommonCore.Actions.ActionGenerator

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.OpenApi.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Hosts
  alias CommonCore.StateSummary.KeycloakSummary

  # TODO(jdt): do we essentially recreate this file for each battery type?
  @client_name "grafana"

  @spec materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t() | nil)
  def materialize(%SystemBattery{} = system_battery, %StateSummary{} = state_summary) do
    [ensure_grafana_client(system_battery, state_summary)]
  end

  defp ensure_grafana_client(%SystemBattery{} = battery, %StateSummary{keycloak_state: key_state} = summary) do
    realm = CommonCore.Defaults.Keycloak.realm_name()
    root_url = "http://#{Hosts.for_battery(summary, battery.type)}"

    # https://web.archive.org/web/20230802094035/https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/
    # https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/keycloak/
    expected = %ClientRepresentation{
      adminUrl: root_url,
      baseUrl: root_url,
      clientId: "grafana-oauth",
      directAccessGrantsEnabled: true,
      enabled: true,
      id: battery.id,
      implicitFlowEnabled: false,
      name: @client_name,
      protocol: "openid-connect",
      publicClient: false,
      redirectUris: ["#{root_url}/login/generic_oauth"],
      rootUrl: root_url,
      standardFlowEnabled: true,
      webOrigins: [root_url]
    }

    case KeycloakSummary.check_client_state(key_state, realm, expected) do
      {:too_early, nil} ->
        nil

      {:exists, _existing} ->
        nil

      {:changed, _existing} ->
        %FreshGeneratedAction{
          action: :sync,
          type: :client,
          realm: realm,
          value: Map.from_struct(expected)
        }

      {:potential_name_change, _existing} ->
        # TODO(jdt): can we change the ID? Do we delete and recreate?
        # For now, just ostrich
        nil

      {:not_found, _} ->
        %FreshGeneratedAction{
          action: :create,
          type: :client,
          realm: realm,
          value: Map.from_struct(expected)
        }
    end
  end
end
