defmodule KubeServices.SystemState.KeycloakSummarizer do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.OpenAPI.KeycloakAdminSchema.RealmRepresentation
  alias CommonCore.StateSummary.KeycloakSummary
  alias CommonCore.StateSummary.RealmOIDCConfiguration
  alias KubeServices.Keycloak.AdminClient
  alias KubeServices.Keycloak.WellknownClient

  require Logger

  @me __MODULE__
  @state_opts []

  typedstruct module: State do
  end

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(opts) do
    {:ok, struct(State, opts)}
  end

  def handle_call(:snapshot, _from, %State{} = state) do
    case try_get_realms() do
      nil ->
        # If there's no realms to even try
        # assume that keycloak is not there.
        {:reply, nil, state}

      {:ok, realms} ->
        # If we get something then try and enrich that
        summary =
          realms
          |> add_all(&add_clients/1)
          |> add_all(&add_users/1)
          |> add_all(&add_required_actions/1)
          |> add_all(&add_flows/1)
          |> get_realm_configurations()
          |> to_summary()

        {:reply, summary, state}

      # Something has gone wrong, but the
      # keycloak summarizer can't stop
      # the whole thing..
      _ ->
        {:reply, nil, state}
    end
  end

  defp to_summary({enriched_realms, realm_configurations}) do
    %KeycloakSummary{realms: enriched_realms, realm_configurations: realm_configurations}
  end

  defp try_get_realms do
    # We call this during start up.
    #
    # The batteries sub-system might not be up.
    # If it's not then
    case Process.whereis(AdminClient) do
      nil -> nil
      _ -> AdminClient.realms()
    end
  end

  defp add_clients(%RealmRepresentation{realm: name} = realm) do
    case AdminClient.clients(name) do
      {:ok, clients} ->
        %{realm | clients: clients}

      _ ->
        realm
    end
  end

  defp add_users(%RealmRepresentation{realm: name} = realm) do
    case AdminClient.users(name) do
      {:ok, users} ->
        %{realm | users: users}

      _ ->
        realm
    end
  end

  defp add_required_actions(%RealmRepresentation{realm: name} = realm) do
    case AdminClient.required_actions(name) do
      {:ok, actions} ->
        %{realm | requiredActions: actions}

      _ ->
        realm
    end
  end

  defp add_flows(%RealmRepresentation{realm: name} = realm) do
    case AdminClient.flows(name) do
      {:ok, flows} ->
        %{realm | authenticationFlows: flows}

      _ ->
        realm
    end
  end

  defp get_realm_configurations(realms) do
    # For each realm try and get the OIDC configuration
    #
    # A bunch of urls that we need to get all the open id connect info.
    realm_configs =
      realms
      |> Enum.map(&get_realm_configuration/1)
      |> Enum.filter(&(&1 != nil))

    {realms, realm_configs}
  end

  defp get_realm_configuration(%RealmRepresentation{realm: name}) do
    with {:ok, configuration} <- WellknownClient.get(name),
         {:ok, realm_config} <- RealmOIDCConfiguration.new(realm: name, oidc_configuration: configuration) do
      realm_config
    else
      _ ->
        nil
    end
  end

  defp add_all(realms, func), do: Enum.map(realms, func)

  def snapshot(target \\ @me) do
    GenServer.call(target, :snapshot, 30_000)
  end
end
