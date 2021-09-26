defmodule KubeServices.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, [keys: :unique, name: KubeServices.Registry.Worker]},
      {KubeExt.ConnectionPool, name: KubeServices.ConnectionPool},
      KubeServices.BaseServicesSupervisor,
      KubeServices.BaseServicesHydrator
    ]

    opts = [strategy: :one_for_one, name: KubeServices.Supervisor]
    sup = Supervisor.start_link(children, opts)
    ControlServer.Services.Defaults.start()
    sup
  end
end
