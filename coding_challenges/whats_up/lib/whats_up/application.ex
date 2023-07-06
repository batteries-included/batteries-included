defmodule WhatsUp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      WhatsUpWeb.Telemetry,
      # Start the Ecto repository
      WhatsUp.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: WhatsUp.PubSub},
      # Start Finch
      {Finch, name: WhatsUp.Finch},
      # Start the Endpoint (http/https)
      WhatsUpWeb.Endpoint
      # Start a worker by calling: WhatsUp.Worker.start_link(arg)
      # {WhatsUp.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WhatsUp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WhatsUpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
