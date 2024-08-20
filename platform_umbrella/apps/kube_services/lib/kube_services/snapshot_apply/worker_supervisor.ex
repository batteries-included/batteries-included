defmodule KubeServices.SnapshotApply.WorkerSupervisor do
  @moduledoc false
  use Supervisor

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [{KubeServices.SnapshotApply.Worker, [running: true]}]

    Logger.debug("Starting snapshot apply worker supervisor tree")

    Supervisor.init(children, strategy: :one_for_all)
  end
end
