defmodule ControlServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ControlServer.Repo,
      # Start the Telemetry supervisor
      ControlServerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ControlServer.PubSub},
      # Start the Endpoint (http/https)
      ControlServerWeb.Endpoint,
      ControlServer.Services.Prometheus
      # Start a worker by calling: ControlServer.Worker.start_link(arg)
      # {ControlServer.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ControlServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ControlServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
