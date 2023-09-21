defmodule KubeServices.Keycloak.ClientManager do
  @moduledoc """
  Responsible for keeping track of Keycloak clients.

  It determines and caches the necessary details for a client.
  This includes managing the client_secret.
  """
  use GenServer
  use TypedStruct

  alias CommonCore.Keycloak.AdminClient
  alias EventCenter.Keycloak.Payload

  require Logger

  @me __MODULE__
  @state_opts ~w(admin_client_target clients_by_id clients_by_name)a

  typedstruct module: State do
    field :admin_client_target, atom | pid, default: AdminClient
    field :clients_by_id, map()
    field :clients_by_name, map()
  end

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.put_new(:clients_by_id, %{})
      |> Keyword.put_new(:clients_by_name, %{})
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  @impl GenServer
  def init(args) do
    :ok = EventCenter.Keycloak.subscribe(:create_client)
    :ok = EventCenter.Keycloak.subscribe(:update_client)

    Process.send_after(@me, {:sync}, 1_000)
    {:ok, struct!(State, args)}
  end

  @impl GenServer
  def handle_info({:sync}, %State{} = state) do
    {:noreply, do_sync(state)}
  end

  @impl GenServer
  def handle_info(%Payload{resource: %{contents: client}}, %State{} = state) do
    {:noreply, update_state_for_client(state, client)}
  end

  @impl GenServer
  def handle_call({:sync}, _from, state) do
    {:reply, :ok, do_sync(state)}
  end

  @impl GenServer
  def handle_call(
        {:client, name_or_id},
        _from,
        %State{clients_by_id: clients_by_id, clients_by_name: clients_by_name} = state
      ) do
    # Try to get by name, if not there, get by id
    client =
      Map.get_lazy(clients_by_name, name_or_id, fn -> Map.get(clients_by_id, name_or_id) end)

    {:reply, client, do_sync(state)}
  end

  def sync(target \\ @me) do
    GenServer.call(target, {:sync})
  end

  def client(target \\ @me, client_name_or_id) do
    GenServer.call(target, {:client, client_name_or_id})
  end

  defp do_sync(state) do
    realm_name = CommonCore.Defaults.Keycloak.realm_name()
    key_state = KubeServices.SystemState.Summarizer.cached_field(:keycloak_state)

    case key_state do
      nil ->
        Process.send_after(@me, {:sync}, 10_000)
        state

      _ ->
        key_state.realms
        |> Enum.filter(&(&1.realm == realm_name))
        |> Enum.flat_map(& &1.clients)
        |> Enum.reduce(state, fn client, state -> update_state_for_client(state, client) end)
    end
  end

  defp update_state_for_client(
         %State{clients_by_id: clients_by_id, clients_by_name: clients_by_name} = state,
         %{id: id, name: name} = client
       ) do
    cb_id = Map.put(clients_by_id, id, client)
    cb_name = Map.put(clients_by_name, name, client)

    %{state | clients_by_id: cb_id, clients_by_name: cb_name}
  end

  defp update_state_for_client(
         %State{clients_by_id: clients_by_id, clients_by_name: clients_by_name} = state,
         %{"id" => id, "name" => name} = client
       ) do
    cb_id = Map.put(clients_by_id, id, client)
    cb_name = Map.put(clients_by_name, name, client)

    %{state | clients_by_id: cb_id, clients_by_name: cb_name}
  end
end
