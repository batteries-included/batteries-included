defmodule CommonCore.StateSummary.KeycloakSummary do
  @moduledoc false
  use TypedStruct

  alias CommonCore.OpenApi.KeycloakAdminSchema

  @derive Jason.Encoder

  typedstruct do
    field :realms, list(KeycloakAdminSchema.RealmRepresentation.t())
  end

  @spec realm_member?(nil | CommonCore.StateSummary.KeycloakSummary.t(), any) :: boolean
  @doc """
  Given a Keycloak summary determine if a realm is already on this keycloak api server.

  Assumes YES if there's no summary yet, so we don't try and create a realm twice during boot up.
  """
  def realm_member?(nil, _), do: true
  def realm_member?(%__MODULE__{realms: nil} = _keycloak_summary, _), do: true

  def realm_member?(%__MODULE__{realms: realms} = _keycloak_summary, realm_name) do
    Enum.any?(realms, fn %KeycloakAdminSchema.RealmRepresentation{} = realm ->
      realm.realm == realm_name
    end)
  end
end
