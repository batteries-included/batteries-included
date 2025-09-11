defmodule KubeServices.KubeState.Canary do
  @moduledoc """
  This is a module that can be used to force a restart of the KubeState.Supervisor
  """
  use GenServer

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(_args) do
    {:ok, %{}}
  end

  def force_restart do
    GenServer.call(__MODULE__, :force_restart)
  end

  @impl GenServer
  def handle_call(:force_restart, _from, state) do
    {:stop, :restart, state, state}
  end
end
