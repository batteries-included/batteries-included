defmodule ControlServer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      ControlServer.Telemetry,
      # Start the Ecto repository
      ControlServer.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ControlServer.PubSub},
      {Task.Supervisor, name: ControlServer.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ControlServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
