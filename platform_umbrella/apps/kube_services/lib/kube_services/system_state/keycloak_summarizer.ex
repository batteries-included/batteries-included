defmodule KubeServices.SystemState.KeycloakSummarizer do
  use GenServer
  use TypedStruct
  alias CommonCore.OpenApi.KeycloakAdminSchema.RealmRepresentation
  alias CommonCore.StateSummary.KeycloakSummary
  alias CommonCore.Keycloak.AdminClient

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
          |> add_all_clients()
          |> add_all_users()
          |> to_summary()

        {:reply, summary, state}

      # Something has gone wrong, but the
      # keycloak summarizer can't stop
      # the whole thing..
      _ ->
        {:reply, nil, state}
    end
  end

  defp to_summary(enriched_realms) do
    %KeycloakSummary{realms: enriched_realms}
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
        %RealmRepresentation{realm | clients: clients}

      _ ->
        realm
    end
  end

  defp add_users(%RealmRepresentation{realm: name} = realm) do
    case AdminClient.users(name) do
      {:ok, users} ->
        %RealmRepresentation{realm | users: users}

      _ ->
        realm
    end
  end

  defp add_all_clients(realms) do
    Enum.map(realms, &add_clients/1)
  end

  defp add_all_users(realms) do
    Enum.map(realms, &add_users/1)
  end

  def snapshot(target \\ @me) do
    GenServer.call(target, :snapshot, 60_000)
  end
end
