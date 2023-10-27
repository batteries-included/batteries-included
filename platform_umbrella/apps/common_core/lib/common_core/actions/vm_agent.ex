# credo:disable-for-this-file Credo.Check.Design.DuplicatedCode
defmodule CommonCore.Actions.VMAgent do
  @moduledoc false
  @behaviour CommonCore.Actions.ActionGenerator

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.OpenApi.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Hosts
  alias CommonCore.StateSummary.KeycloakSummary

  @client_name "vm_agent"

  @spec materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t() | nil)
  def materialize(%SystemBattery{} = system_battery, %StateSummary{} = state_summary) do
    [ensure_vm_agent_client(system_battery, state_summary)]
  end

  defp ensure_vm_agent_client(%SystemBattery{} = battery, %StateSummary{keycloak_state: key_state} = summary) do
    realm = CommonCore.Defaults.Keycloak.realm_name()
    root_url = "http://#{Hosts.for_battery(summary, battery.type)}"

    expected = %ClientRepresentation{
      clientId: "#{@client_name}-oauth",
      directAccessGrantsEnabled: true,
      enabled: true,
      id: battery.id,
      implicitFlowEnabled: false,
      name: @client_name,
      protocol: "openid-connect",
      publicClient: false,
      standardFlowEnabled: true,
      rootUrl: root_url,
      redirectUris: ["/*"]
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
