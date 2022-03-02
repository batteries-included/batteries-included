defmodule KubeState.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Bella.Sys.Logger.attach()
    conn = KubeExt.ConnectionPool.get()

    children = [
      # Starts a worker by calling: KubeState.Worker.start_link(arg)
      # {KubeState.Worker, arg}
      {Bella.Watcher.Worker, [watcher: KubeState.NamespaceWatcher, connection: conn]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KubeState.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
