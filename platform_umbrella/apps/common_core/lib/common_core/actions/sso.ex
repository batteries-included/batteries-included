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

  # if we don't have a good summary, do nothing
  defp ensure_totp_flow(_, %StateSummary{keycloak_state: nil}), do: nil
  defp ensure_totp_flow(_, %StateSummary{keycloak_state: %KeycloakSummary{realms: []}}), do: nil

  # make sure conditional otp form is configured
  defp ensure_totp_flow(%SystemBattery{config: %SSOConfig{mfa: mfa}}, %StateSummary{} = _state_summary) do
    requirement = if mfa, do: "REQUIRED", else: "CONDITIONAL"

    %FreshGeneratedAction{
      action: :sync,
      type: :flow_execution,
      realm: Keycloak.realm_name(),
      value: %{flow_alias: "browser", display_name: "Browser - Conditional 2FA", requirement: requirement}
    }
  end

  # if we don't have a good summary, do nothing
  defp ensure_totp_required_action(_, %StateSummary{keycloak_state: nil}), do: nil
  defp ensure_totp_required_action(_, %StateSummary{keycloak_state: %KeycloakSummary{realms: []}}), do: nil

  # make sure TOTP configure page is enabled / disabled
  defp ensure_totp_required_action(
         %SystemBattery{config: %SSOConfig{mfa: mfa}},
         %StateSummary{keycloak_state: %KeycloakSummary{realms: realms}} = _state_summary
       ) do
    realms
    |> Enum.find(fn %RealmRepresentation{realm: name} = _realm -> name == Keycloak.realm_name() end)
    |> determine_totp_action(mfa)
  end

  #
  # Helpers
  #

  defp determine_totp_action(nil, _mfa), do: nil
  defp determine_totp_action(%RealmRepresentation{requiredActions: nil}, _mfa), do: nil

  defp determine_totp_action(%RealmRepresentation{requiredActions: actions, realm: name}, mfa) do
    case Enum.find(actions, &(&1.alias == "CONFIGURE_TOTP")) do
      nil ->
        Logger.warning("Couldn't find OTP required action")
        nil

      %RequiredActionProviderRepresentation{defaultAction: ^mfa} ->
        nil

      %RequiredActionProviderRepresentation{} = action ->
        %FreshGeneratedAction{
          action: :sync,
          type: :required_action,
          realm: name,
          value: Map.from_struct(%{action | defaultAction: mfa})
        }
    end
  end
end
