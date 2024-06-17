defmodule HomeBaseWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      HomeBaseWeb.Telemetry,
      HomeBaseWeb.Endpoint
    ]

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
