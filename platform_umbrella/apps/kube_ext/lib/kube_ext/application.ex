defmodule KubeExt.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      KubeExt.ConnectionPool,
      {KubeExt.KubeState.Runner, name: KubeExt.KubeState.default_state_table()}
    ]

    opts = [strategy: :one_for_one, name: KubeExt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
