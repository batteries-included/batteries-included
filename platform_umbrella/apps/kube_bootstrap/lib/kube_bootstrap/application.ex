defmodule KubeBootstrap.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl Application
  @spec start(any(), keyword()) :: {:error, any()} | {:ok, pid()}
  def start(_type, _args) do
    children = [
      {CommonCore.ConnectionPool, name: KubeBootstrap.ConnectionPool},
      {Task.Supervisor, name: KubeBootstrap.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: KubeBootstrap.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
