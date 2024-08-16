defmodule KubeServices.Keycloak.TokenStorage do
  @moduledoc false
  use GenServer
  use TypedStruct

  @me __MODULE__

  typedstruct module: State do
    field :name, atom(), default: KubeServices.Keycloak.TokenStorage
  end

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, @me)
    GenServer.start_link(__MODULE__, opts, opts)
  end

  @impl GenServer
  def init(opts) do
    state = struct(State, opts)
    _table = :ets.new(state.name, [:protected, :set, :named_table])
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:put_token, session_id, token}, _from, %{name: name} = state) do
    :ets.insert(name, {session_id, token})
    {:reply, :ok, state}
  end

  def handle_call({:delete_token, session_id}, _from, %{name: name} = state) do
    :ets.delete(name, session_id)
    {:reply, :ok, state}
  end

  def put_token(target \\ @me, session_id, token) do
    GenServer.call(target, {:put_token, session_id, token})
  end

  def delete_token(target \\ @me, session_id) do
    GenServer.call(target, {:delete_token, session_id})
  end

  def get_token(target \\ @me, session_id) do
    case :ets.lookup(target, session_id) do
      [] -> nil
      [{_, token}] -> token
    end
  rescue
    _ -> nil
  end
end
