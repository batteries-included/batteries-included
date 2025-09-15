defmodule KubeServices.RoboSRE.RestartKubeStateExecutor do
  @moduledoc false
  @behaviour KubeServices.RoboSRE.Executor

  use GenServer
  use TypedStruct

  alias CommonCore.RoboSRE.Action
  alias KubeServices.KubeState.Canary

  require Logger

  @state_opts [:canary]
  @me __MODULE__

  typedstruct module: State do
    field :canary, module(), default: Canary
  end

  def start_link(opts \\ []) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    {init_opts, opts} = Keyword.split(opts, @state_opts)

    GenServer.start_link(__MODULE__, init_opts, opts)
  end

  @impl GenServer
  def init(opts) do
    canary = Keyword.get(opts, :canary, Canary)
    state = %State{canary: canary}

    {:ok, state}
  end

  @impl KubeServices.RoboSRE.Executor
  @spec execute(Action.t()) :: {:ok, any()} | {:error, any()}
  def execute(%Action{action_type: :restart_kube_state} = action) do
    GenServer.call(@me, {:execute, action})
  end

  def execute(%Action{action_type: other}) do
    {:error, {:unsupported_action_type, other}}
  end

  @impl GenServer
  def handle_call({:execute, %Action{action_type: :restart_kube_state}}, _from, %State{canary: canary} = state) do
    Logger.info("Restarting KubeState via Canary")

    try do
      _ = canary.force_restart()
      {:reply, {:ok, :restarted}, state}
    rescue
      error ->
        Logger.error("Failed to restart KubeState: #{inspect(error)}")
        {:reply, {:error, {:restart_failed, error}}, state}
    end
  end
end
