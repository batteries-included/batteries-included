defmodule CommonCore.Actions.SSO do
  @moduledoc false

  @behaviour CommonCore.Actions.ActionGenerator

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SSOConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Defaults.Keycloak
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RealmRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RequiredActionProviderRepresentation
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KeycloakSummary

  require Logger

  @spec materialize(SystemBattery.t(), StateSummary.t()) :: list(FreshGeneratedAction.t() | nil)
  def materialize(%SystemBattery{} = system_battery, %StateSummary{} = state_summary) do
    [ping(), ensure_totp_flow(system_battery, state_summary), ensure_totp_required_action(system_battery, state_summary)]
  end

  defp ping, do: %FreshGeneratedAction{action: :ping, type: :realm, value: %{}}

  # if mfa isn't enabled, do nothing
  defp ensure_totp_flow(%SystemBattery{config: %SSOConfig{mfa: false}}, %StateSummary{} = _state_summary), do: nil
  # if we don't have a good summary, do nothing
  defp ensure_totp_flow(_, %StateSummary{keycloak_state: nil}), do: nil
  defp ensure_totp_flow(_, %StateSummary{keycloak_state: %KeycloakSummary{realms: []}}), do: nil

  # if mfa and summary, make sure conditional otp form is required
  defp ensure_totp_flow(%SystemBattery{config: %SSOConfig{mfa: true}}, %StateSummary{} = _state_summary) do
    %FreshGeneratedAction{
      action: :sync,
      type: :flow_execution,
      realm: Keycloak.realm_name(),
      value: %{flow_alias: "browser", display_name: "Browser - Conditional OTP"}
    }
  end

  # if mfa isn't enabled, do nothing
  defp ensure_totp_required_action(%SystemBattery{config: %SSOConfig{mfa: false}}, _), do: nil
  # if we don't have a good summary, do nothing
  defp ensure_totp_required_action(_, %StateSummary{keycloak_state: nil}), do: nil
  defp ensure_totp_required_action(_, %StateSummary{keycloak_state: %KeycloakSummary{realms: []}}), do: nil

  # if mfa and summary, make sure TOTP configure page is enabled
  defp ensure_totp_required_action(
         %SystemBattery{config: %SSOConfig{mfa: true}},
         %StateSummary{keycloak_state: %KeycloakSummary{realms: realms}} = _state_summary
       ) do
    realms
    |> Enum.find(fn %RealmRepresentation{realm: name} = _realm -> name == Keycloak.realm_name() end)
    |> determine_totp_action()
  end

  #
  # Helpers
  #

  defp determine_totp_action(nil), do: nil
  defp determine_totp_action(%RealmRepresentation{requiredActions: nil}), do: nil

  defp determine_totp_action(%RealmRepresentation{requiredActions: actions, realm: name}) do
    case Enum.find(actions, &(&1.alias == "CONFIGURE_TOTP")) do
      nil ->
        Logger.warning("Couldn't find OTP required action")
        nil

      %RequiredActionProviderRepresentation{defaultAction: true} ->
        nil

      %RequiredActionProviderRepresentation{defaultAction: false} = action ->
        %FreshGeneratedAction{
          action: :sync,
          type: :required_action,
          realm: name,
          value: Map.from_struct(%RequiredActionProviderRepresentation{action | defaultAction: true})
        }
    end
  end
end
