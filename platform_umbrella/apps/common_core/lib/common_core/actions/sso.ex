defmodule CommonCore.Actions.SSO do
  @moduledoc false
  @behaviour CommonCore.Actions.ActionGenerator

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KeycloakSummary

  @spec materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t() | nil)
  def materialize(%SystemBattery{} = system_battery, %StateSummary{} = state_summary) do
    [ensure_core_realm(system_battery, state_summary)]
  end

  defp ensure_core_realm(%SystemBattery{} = _system_battery, %StateSummary{keycloak_state: key_state} = _state_summary) do
    realm_name = CommonCore.Defaults.Keycloak.realm_name()
    # No action needed if the realm already exists
    if KeycloakSummary.realm_member?(key_state, realm_name) do
      nil
    else
      %FreshGeneratedAction{
        action: :create,
        type: :realm,
        realm: nil,
        value: %{
          realm: realm_name,
          displayName: "Batteries Included",
          enabled: true
        }
      }
    end
  end
end
