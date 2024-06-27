defmodule CommonCore.Actions.SSO do
  @moduledoc false
  @behaviour CommonCore.Actions.ActionGenerator

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KeycloakSummary

  @spec materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t() | nil)
  def materialize(%SystemBattery{} = _system_battery, %StateSummary{} = state_summary) do
    [ping(), ensure_core_realm(state_summary)]
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
          enabled: true
        }
      }
    end
  end

  defp ping, do: %FreshGeneratedAction{action: :ping, type: :realm, value: %{}}
end
