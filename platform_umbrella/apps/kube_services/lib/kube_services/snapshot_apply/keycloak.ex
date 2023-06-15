defmodule KubeServices.SnapshotApply.KeycloakApply do
  use GenServer
  use TypedStruct

  alias ControlServer.SnapshotApply.KeycloakEctoSteps
  alias ControlServer.SnapshotApply.UmbrellaSnapshot

  require Logger

  @me __MODULE__
  @state_opts []

  typedstruct module: State do
  end

  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  def init(opts) do
    {:ok, struct(State, opts)}
  end

  def prepare(%UmbrellaSnapshot{id: id} = _us) do
    args = %{umbrella_snapshot_id: id}
    KeycloakEctoSteps.create_snap(args)
  end
end
