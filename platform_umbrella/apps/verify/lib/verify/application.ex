defmodule Verify.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {Task.Supervisor, [name: Verify.TaskSupervisor]},
      {CommonCore.Installs.Generator, [name: Verify.Installs.Generator]},
      {Verify.KindInstallWorker, [name: Verify.KindInstallWorker]},
      # for BatteryInstallWorker
      {Registry, keys: :unique, name: Verify.Registry}
    ]

    opts = [strategy: :one_for_one, name: Verify.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
