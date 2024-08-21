defmodule CommonCore.StateSummary.RealmOIDCConfiguration do
  @moduledoc false
  use CommonCore, :embedded_schema

  batt_embedded_schema do
    field :realm, :string
    field :oidc_configuration, CommonCore.OpenAPI.OIDC.OIDCConfiguration
  end

  def get_realm_configuration(state, realm) do
    Enum.find(state.realm_configurations || [], &(&1.realm == realm))
  end
end
