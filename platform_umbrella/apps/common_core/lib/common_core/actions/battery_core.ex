defmodule CommonCore.Actions.BatteryCore do
  @moduledoc false

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KeycloakSummary

  @spec materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t() | nil)
  def materialize(%SystemBattery{} = _system_battery, %StateSummary{} = state_summary) do
    [ensure_core_realm(state_summary)]
  end

  defp ensure_core_realm(%StateSummary{keycloak_state: key_state} = _state_summary) do
    realm_name = CommonCore.Defaults.Keycloak.realm_name()
    # No action needed if the realm already exists
    if KeycloakSummary.realm_member?(key_state, realm_name) do
      nil
    else
      %FreshGeneratedAction{
        action: :create,
        type: :realm,
        realm: nil,
        # Keycloak RealmRepresentation
        value: %{
          # The realm name is an identifier for the realm and cannot be changed.
          realm: realm_name,
          # The display name for the realm.
          displayName: "Batteries Included",
          # Allows users to click the remember me checkbox.
          rememberMe: true,
          social: false,
          # This should match the name field in keyclaok-theme/package.json
          # It's the Batteries Included theme built with keycloakify.
          loginTheme: "bi-keycloak-theme",
          enabled: true
        }
      }
    end
  end
end
