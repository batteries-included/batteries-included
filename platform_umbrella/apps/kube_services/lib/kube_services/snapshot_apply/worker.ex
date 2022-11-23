defmodule KubeServices.SnapshotApply.Worker do
  use Oban.Worker,
    max_attempts: 3

  alias ControlServer.SnapshotApply.EctoSteps

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{} = _args}) do
    with {:ok, snap} <- EctoSteps.create_snap() do
      KubeServices.SnapshotApply.Apply.run(snap)
    end
  end

  def start!(opts \\ []) do
    %{} |> new(opts) |> Oban.insert!()
  end
end
