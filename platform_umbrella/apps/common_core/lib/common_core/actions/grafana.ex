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

    expected = %ClientRepresentation{
      enabled: true,
      id: battery.id,
      name: @client_name,
      secret: CommonCore.Defaults.random_key_string(),
      rootUrl: "http://#{Hosts.for_battery(summary, battery.type)}"
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
