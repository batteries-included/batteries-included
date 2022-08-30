defmodule KubeRawResources.Application do
  @moduledoc false
  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    Logger.debug("Starting KubeRawResources applicaiton")

    children = [
      {Task.Supervisor, name: KubeRawResources.TaskSupervisor},
      {KubeExt.ConnectionPool, name: KubeRawResources.ConnectionPool}
    ]

    opts = [strategy: :one_for_one, name: KubeRawResources.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
