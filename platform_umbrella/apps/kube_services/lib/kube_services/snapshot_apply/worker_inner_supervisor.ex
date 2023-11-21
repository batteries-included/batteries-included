defmodule KubeServices.SnapshotApply.WorkerInnerSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.Resources.FilterResource, as: F
  alias KubeServices.SystemState.Summarizer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    summary = Summarizer.cached()

    sso_running = F.sso_installed?(summary)
    children = [{KubeServices.SnapshotApply.Worker, [sso_running: sso_running, running: true]}]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
