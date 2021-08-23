defmodule KubeExt.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      KubeExt.ConnectionPool
    ]

    opts = [strategy: :one_for_one, name: KubeExt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
