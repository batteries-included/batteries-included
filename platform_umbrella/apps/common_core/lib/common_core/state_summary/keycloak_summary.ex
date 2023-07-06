defmodule CommonCore.StateSummary.KeycloakSummary do
  use TypedStruct

  alias CommonCore.OpenApi.KeycloakAdminSchema
  @derive Jason.Encoder

  typedstruct do
    field :realms, list(KeycloakAdminSchema.RealmRepresentation.t())
  end
end
