defmodule KubeServices.SnapshotApply.Worker do
  use Oban.Worker,
    max_attempts: 3

  alias KubeServices.SnapshotApply.Apply

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{} = _args}) do
    Apply.run()
  end

  def start!(opts \\ []) do
    %{} |> new(opts) |> Oban.insert!()
  end
end
