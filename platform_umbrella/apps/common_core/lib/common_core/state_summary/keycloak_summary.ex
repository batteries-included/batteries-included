defmodule CommonCore.StateSummary.KeycloakSummary do
  use TypedStruct

  alias CommonCore.OpenApi.KeycloakAdminSchema
  @derive Jason.Encoder

  typedstruct do
    field :realms, list(KeycloakAdminSchema.RealmRepresentation.t())
  end

  def realm_member?(nil, _), do: false

  def realm_member?(%__MODULE__{realms: realms} = _keycloak_summary, realm_name) do
    Enum.any?(realms, fn %KeycloakAdminSchema.RealmRepresentation{} = realm ->
      realm.realm == realm_name
    end)
  end
end
