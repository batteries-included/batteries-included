defmodule CommonCore.StateSummary.Creds do
  @moduledoc false
  import CommonCore.StateSummary.Batteries

  alias CommonCore.Batteries.KeycloakConfig
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.StateSummary

  @doc """
  Access for the configured root username that
  batteries included relies on to access Keycloak

  This returns nil if the keycloak battery is not enabled.
  """
  @spec root_keycloak_username(StateSummary.t()) :: binary() | nil
  def root_keycloak_username(%StateSummary{} = summary) do
    case keycloak_config(summary) do
      %KeycloakConfig{} = config -> config.admin_username
      _ -> nil
    end
  end

  @doc """
  Access for the configured root password that
  batteries included relies on to access Keycloak

  This returns nil if the keycloak battery is not enabled.
  """
  @spec root_keycloak_password(StateSummary.t()) :: binary() | nil
  def root_keycloak_password(%StateSummary{} = summary) do
    case keycloak_config(summary) do
      %KeycloakConfig{} = config -> config.admin_password
      _ -> nil
    end
  end

  defp keycloak_config(summary) do
    with %SystemBattery{} = sb <- get_battery(summary, :keycloak),
         %KeycloakConfig{} = config <- sb.config do
      config
    else
      _ ->
        nil
    end
  end
end
