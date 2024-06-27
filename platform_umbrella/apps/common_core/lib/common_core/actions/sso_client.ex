defmodule CommonCore.Actions.SSOClient do
  @moduledoc """
  Module to consolidate the logic for creating and maintaining Keycloak clients.

  In most cases, to add a client for a battery, it is sufficient to `use CommonCore.Actions.SSOClient`
  and to define the `configure_client/3` callback to configure the Keycloak client settings.

  ## Examples

  ```elixir
  defmodule MyBatteryThatNeedsAKeycloakClient do
    use CommonCore.Actions.SSOClient

    configure_client(_battery, _state, default_client) do
      {default_client, []}
    end
  end
  ```

  See the documentation for `__using__/1` and `CommonCore.Actions.SSOClient.ClientConfigurator.configure_client/3` for additional details.
  """

  alias CommonCore.Actions.FreshGeneratedAction
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KeycloakSummary

  @default_client_fields ~w(
    adminUrl baseUrl clientId directAccessGrantsEnabled
    enabled id implicitFlowEnabled name
    protocol publicClient redirectUris rootUrl
    standardFlowEnabled webOrigins
  )a

  def default_client_fields, do: @default_client_fields

  defmodule ClientConfigurator do
    @moduledoc false
    @type f :: (SystemBattery.t(), StateSummary.t(), ClientRepresentation.t() -> {ClientRepresentation.t(), keyword()})
    @callback configure(
                SystemBattery.t(),
                StateSummary.t(),
                ClientRepresentation.t()
              ) :: {ClientRepresentation.t(), keyword()}
  end

  @doc """
  Sets up the calling module for creating SSO clients.
  """
  defmacro __using__(opts) do
    [module_setup(opts), client_name(opts), define_materialize(opts)]
  end

  defp module_setup(_opts) do
    quote do
      @behaviour CommonCore.Actions.ActionGenerator
      @behaviour unquote(__MODULE__.ClientConfigurator)

      import unquote(__MODULE__)

      alias CommonCore.Batteries.SystemBattery
      alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
      alias CommonCore.StateSummary
      alias unquote(__MODULE__.ClientConfigurator)
    end
  end

  defp client_name(opts) do
    name =
      opts
      |> Keyword.get(:client_name, nil)
      |> to_string()

    quote do
      @client_name unquote(name)

      def client_name, do: @client_name
    end
  end

  defp define_materialize(_opts) do
    quote do
      @impl CommonCore.Actions.ActionGenerator
      def materialize(%SystemBattery{} = system_battery, %StateSummary{} = state_summary) do
        [generate_client_action(system_battery, state_summary, client_name(), &configure/3)]
      end

      @impl CommonCore.Actions.SSOClient.ClientConfigurator
      def configure(_battery, _state, client), do: {client, []}

      defoverridable materialize: 2, configure: 3
    end
  end

  @doc """
  Called by `materialize/2` to determine the client desired state and what action may be needed to bring actual to desired.

  Uses an implementation of `CommonCore.Actions.SSOClient.ClientConfigurator` to delegate client desired state definition to each battery.
  """
  @spec generate_client_action(SystemBattery.t(), StateSummary.t(), String.t(), ClientConfigurator.f()) ::
          FreshGeneratedAction.t() | nil
  def generate_client_action(
        %SystemBattery{id: battery_uuid, type: battery_type} = battery,
        %StateSummary{} = summary,
        client_name,
        func
      ) do
    realm = CommonCore.Defaults.Keycloak.realm_name()

    root_url = summary |> CommonCore.StateSummary.URLs.uri_for_battery(battery_type) |> URI.to_string()

    case BatteryUUID.dump(battery_uuid) do
      {:ok, raw_id} ->
        # get the default settings
        base_client = default_client(Base.encode16(raw_id), client_name, root_url)
        # and the additional fields as proscribed by calling module
        {client, additional_client_fields} = func.(battery, summary, base_client)

        # need the list of fields that we're populating so we know if something has changed
        fields = unquote(@default_client_fields) ++ additional_client_fields

        determine_action(summary.keycloak_state, realm, client, fields)

      _ ->
        nil
    end
  end

  @doc """
  Sets up the default Keycloak client settings for OpenID Connect.
  """
  @spec default_client(String.t(), String.t(), String.t()) :: ClientRepresentation.t()
  def default_client(id, name, root_url) do
    %ClientRepresentation{
      adminUrl: root_url,
      baseUrl: root_url,
      clientId: "#{name}-oauth",
      directAccessGrantsEnabled: true,
      enabled: true,
      id: id,
      implicitFlowEnabled: false,
      name: name,
      protocol: "openid-connect",
      publicClient: false,
      redirectUris: ["#{root_url}/*"],
      rootUrl: root_url,
      standardFlowEnabled: true,
      webOrigins: [root_url]
    }
  end

  @doc """
  Checks against the current state of the client to determine the necessary action to take e.g. `:sync`, `:create`, or nothing.

  `fields` is the list of client fields that should be checked to determine if something has changed.
  """
  @spec determine_action(KeycloakSummary.t(), String.t(), ClientRepresentation.t(), list(atom())) ::
          FreshGeneratedAction.t() | nil
  # before a keycloak summary has been generated, nothing to do, return nil
  def determine_action(nil, _, _, _), do: nil

  def determine_action(%KeycloakSummary{} = keycloak_state, realm, expected, fields) do
    case KeycloakSummary.check_client_state(keycloak_state, realm, expected, fields) do
      {:too_early, nil} ->
        nil

      {:exists, _existing} ->
        nil

      {:changed, _existing} ->
        %FreshGeneratedAction{
          action: :sync,
          type: :client,
          realm: realm,
          value: Map.from_struct(expected)
        }

      {:potential_name_change, _existing} ->
        # do something here eventually
        nil

      {:not_found, _} ->
        %FreshGeneratedAction{
          action: :create,
          type: :client,
          realm: realm,
          value: Map.from_struct(expected)
        }
    end
  end
end
