defmodule CommonCore.StateSummary.KeycloakSummary do
  @moduledoc false
  use TypedStruct

  alias CommonCore.OpenApi.KeycloakAdminSchema
  alias CommonCore.OpenApi.KeycloakAdminSchema.ClientRepresentation

  require Logger

  @derive Jason.Encoder
  @check_fields ~w(
    adminUrl baseUrl clientId directAccessGrantsEnabled
    enabled id implicitFlowEnabled name
    protocol publicClient redirectUris rootUrl
    standardFlowEnabled webOrigins
  )a

  typedstruct do
    field :realms, list(KeycloakAdminSchema.RealmRepresentation.t())
  end

  @spec realm_member?(nil | t(), any) :: boolean
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

  @spec check_client_state(
          nil | t(),
          binary(),
          ClientRepresentation.t() | nil
        ) ::
          {:too_early, nil}
          | {:exists, ClientRepresentation.t()}
          | {:changed, ClientRepresentation.t()}
          | {:potential_name_change, ClientRepresentation.t()}
          | {:not_found, nil}
  @doc """
  Given a KeycloakSummary determine if a client exists.

  Assumes YES if there's no summary yet, so we don't try and create a client twice during boot up.
  """

  def check_client_state(nil, _realm, _), do: {:too_early, nil}
  def check_client_state(%__MODULE__{realms: nil}, _realm, _), do: {:too_early, nil}

  def check_client_state(%__MODULE__{realms: _realms} = summary, realm, client) do
    clients = clients_for_realm(summary, realm)

    existing = Enum.find(clients, &(&1.id == client.id))
    potential_name_change = Enum.find(clients, &(&1.name == client.name))
    is_same = scrub_client(existing) == scrub_client(client)

    cond do
      # client exists and no changes needed
      is_same ->
        {:exists, existing}

      # client exists but is different than desired
      existing != nil ->
        {:changed, existing}

      # we found a client with the same name put different ID, hopefully this doesn't happen
      potential_name_change != nil ->
        Logger.warning("Client exists but seems to have the wrong ID: #{inspect(potential_name_change)}")

        {:potential_name_change, potential_name_change}

      # otherwise, we didn't find one
      true ->
        {:not_found, nil}
    end
  end

  defp scrub_client(client) when is_nil(client), do: nil

  # TODO(jdt): this will probably need to be different per client?
  defp scrub_client(client) do
    Map.take(client, @check_fields)
  end

  def clients_for_realm(%__MODULE__{realms: realms}, realm) do
    existing_realm = Enum.find(realms, &(&1.realm == realm))

    case existing_realm do
      nil ->
        []

      _ ->
        existing_realm.clients
    end
  end
end
