defmodule KubeServices.SnapshotApply.KeycloakApply do
  use GenServer
  use TypedStruct

  alias CommonCore.Actions.RootActionGenerator
  alias ControlServer.SnapshotApply.KeycloakEctoSteps
  alias ControlServer.SnapshotApply.UmbrellaSnapshot
  alias ControlServer.SnapshotApply.KeycloakSnapshot
  alias CommonCore.StateSummary

  require Logger

  @me __MODULE__
  @state_opts []

  typedstruct module: State do
  end

  @spec start_link(keyword()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  @impl GenServer
  @spec init(keyword()) :: {:ok, State.t()}
  def init(opts \\ []) do
    {:ok, struct(State, opts)}
  end

  @spec prepare(ControlServer.SnapshotApply.UmbrellaSnapshot.t()) :: any
  def prepare(%UmbrellaSnapshot{id: id} = _us) do
    args = %{umbrella_snapshot_id: id}
    KeycloakEctoSteps.create_snap(args)
  end

  @spec generate(KeycloakSnapshot.t(), StateSummary.t()) :: any
  def generate(snap, summary) do
    GenServer.call(@me, {:generate, snap, summary}, 600_000)
  end

  @impl GenServer
  def handle_call({:generate, snap, summary}, _from, state) do
    {:reply, do_generate(snap, summary, state), state}
  end

  defp do_generate(%KeycloakSnapshot{} = snap, %StateSummary{} = summary, _state) do
    with {:ok, up_g_snap} <- KeycloakEctoSteps.update_snap_status(snap, :generation),
         base_actions <- RootActionGenerator.materialize(summary),
         {:ok, %{actions: actions}} <- KeycloakEctoSteps.snap_generation(up_g_snap, base_actions) do
      {:ok, {base_actions, actions}}
    end
  end
end
