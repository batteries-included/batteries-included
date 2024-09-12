defmodule CommonCore.StateSummary.KeycloakSummary do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.OpenAPI.KeycloakAdminSchema
  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.StateSummary.RealmOIDCConfiguration

  require Logger

  batt_embedded_schema do
    embeds_many :realms, KeycloakAdminSchema.RealmRepresentation
    embeds_many :realm_configurations, RealmOIDCConfiguration
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
          ClientRepresentation.t() | nil,
          list(atom())
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

  def check_client_state(nil, _realm, _, _), do: {:too_early, nil}
  def check_client_state(%__MODULE__{realms: nil}, _realm, _, _), do: {:too_early, nil}

  def check_client_state(%__MODULE__{realms: _realms} = summary, realm, client, fields) do
    clients = clients_for_realm(summary, realm)

    existing = Enum.find(clients, &(&1.id == client.id))
    potential_name_change = Enum.find(clients, &(&1.name == client.name))
    is_same = scrub_client(existing, fields) == scrub_client(client, fields)

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

  def clients_for_realm(%__MODULE__{realms: realms}, realm) do
    existing_realm = Enum.find(realms, &(&1.realm == realm))

    case existing_realm do
      nil ->
        []

      _ ->
        existing_realm.clients
    end
  end

  @spec client(t(), binary()) ::
          %{realm: binary(), client: ClientRepresentation.t()} | nil
  def client(nil, _name), do: nil
  def client(%__MODULE__{realms: nil}, _name), do: nil

  def client(%__MODULE__{realms: realms}, name) do
    clients =
      realms
      |> Enum.flat_map(fn realm ->
        Enum.map(realm.clients, fn client ->
          {client.name, %{realm: realm.realm, client: client}}
        end)
      end)
      |> Map.new()

    Map.get(clients, name)
  end

  defp scrub_client(client, _fields) when is_nil(client), do: nil

  defp scrub_client(client, fields), do: client |> Map.take(fields) |> Map.new(fn f -> normalize_field(f) end)

  defp normalize_field({key, val}) when is_list(val), do: {key, Enum.sort(val)}
  defp normalize_field({_key, _val} = field), do: field
end
