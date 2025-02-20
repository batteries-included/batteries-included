defmodule CommonCore.JWK.Cache do
  @moduledoc """
  This module is a GenServer that caches JWKs.

  It memoizes JWKs to avoid repeated calls to read the pem files.
  """
  use GenServer
  use TypedStruct

  typedstruct module: State do
    field :cache, map(), default: %{}
    field :loader, atom(), default: CommonCore.JWK.Loader
  end

  @state_opts ~w(cache loader)a

  def start_link(opts) do
    {opts, genserver_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, opts, genserver_opts)
  end

  def init(opts) do
    {:ok, struct!(%State{}, opts)}
  end

  def get(target \\ __MODULE__, key_name) do
    GenServer.call(target, {:get, key_name})
  end

  def handle_call({:get, key_name}, _from, state) do
    # We use a different value from nil as the sentinel
    # so that that the negative can be cached.
    case Map.get(state.cache, key_name, :missing) do
      :missing ->
        read(state, key_name)

      key ->
        {:reply, key, state}
    end
  end

  defp read(%{loader: loader, cache: cache} = state, key_name) do
    key = loader.get(key_name)
    new_state = %{state | cache: Map.put(cache, key_name, key)}
    {:reply, key, new_state}
  end
end
