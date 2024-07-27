defmodule KubeServices.SnapshotApply.WorkerInnerSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.StateSummary.Batteries
  alias KubeServices.SystemState.Summarizer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    summary = Summarizer.cached()

    keycloak_enabled = Batteries.keycloak_installed?(summary)
    children = [{KubeServices.SnapshotApply.Worker, [keycloak_enabled: keycloak_enabled, running: true]}]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
