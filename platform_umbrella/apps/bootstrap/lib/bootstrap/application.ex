defmodule Bootstrap.Application do
  @moduledoc false
  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    Logger.debug(
      "Starting Bootstrap applicaiton with #{Bootstrap.TaskSupervisor} task supervisor"
    )

    children = [
      {Task.Supervisor, name: Bootstrap.TaskSupervisor},
      {KubeExt.ConnectionPool, name: Bootstrap.ConnectionPool}
    ]

    opts = [strategy: :one_for_one, name: Bootstrap.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
