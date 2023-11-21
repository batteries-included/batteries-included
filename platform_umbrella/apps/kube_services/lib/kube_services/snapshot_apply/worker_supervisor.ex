defmodule KubeServices.SnapshotApply.WorkerSupervisor do
  @moduledoc false
  use Supervisor

  alias CommonCore.Resources.FilterResource, as: F

  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    children = [
      KubeServices.SnapshotApply.WorkerInnerSupervisor,
      # # Then start a genserver that monitors the system state and reconfigures if needed
      {KubeServices.SystemState.ReconfigCanary, [methods: [&F.sso_installed?/1]]}
    ]

    Logger.debug("Starting snapshot apply worker supervisor tree")

    Supervisor.init(children, strategy: :one_for_all)
  end
end
