defmodule HomeBaseWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HomeBaseWeb.Telemetry,
      # Start the Endpoint (http/https)
      HomeBaseWeb.Endpoint
      # Start a worker by calling: HomeBaseWeb.Worker.start_link(arg)
      # {HomeBaseWeb.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HomeBaseWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    HomeBaseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
